require 'optparse'
require 'roo'
require 'whole_history_rating'

$options = {
    :verbose => false,
    :handicap => 9, # acceptable maximum handicap
    :weight => 100.0, # weight between each dan/kyu
    :output => {
        :records => false,
        :latest => false,
        :chrono => false,
    },
}

def import(filename)
    puts "Import: " + filename
    excel = Roo::Spreadsheet.open(filename)
    # puts excel.info

    excel.default_sheet = excel.sheets[0] # Record
    records = excel.parse(
        date: "Date",
        black: "Black",
        white: "White",
        handicap: "Handicap",
        difference: "Difference",
        winner: "Winner Side",
        result: "Result",
        organization: "Organization",
        match: "Match",
        round: "Round",
        link: "OGS Link",
        remark: "Remark",
        clean: true
    )

    excel.default_sheet = excel.sheets[1] # Player
    players = excel.parse(
        name: "Player",
        initial: "Initial Rank",
        flat: "Flat Rank",
        cert: "Cert Rank",
        guess: "Guess Rank",
        clean: true
    )

    return records, players
end

def setupelos(players)
    elos = {
        "9p"  => 2940,
        "8p"  => 2910,
        "7p"  => 2880,
        "6p"  => 2850,
        "5p"  => 2820,
        "4p"  => 2790,
        "3p"  => 2760,
        "2p"  => 2730,
        "1p"  => 2700,
        "7d"  => 2700,
        "6d"  => 2600,
        "5d"  => 2500,
        "4d"  => 2400,
        "3d"  => 2300,
        "2d"  => 2200,
        "1d"  => 2100,
        "1k"  => 2000,
        "2k"  => 1900,
        "3k"  => 1800,
        "4k"  => 1700,
        "5k"  => 1600,
        "6k"  => 1500,
        "7k"  => 1400,
        "8k"  => 1300,
        "9k"  => 1200,
        "10k" => 1100,
        "11k" => 1000,
        "12k" =>  900,
        "13k" =>  800,
        "14k" =>  700,
        "15k" =>  600,
        "16k" =>  500,
        "17k" =>  400,
        "18k" =>  300,
        "19k" =>  200,
        "20k" =>  100,
    }
    players.each do |player|
        player[:initial_elo] = elos[player[:initial]] || elos["1d"]
        player[:flat_elo]    = elos[player[:flat]]    || elos["1d"]
        player[:cert_elo]    = elos[player[:cert]]    || elos["1d"]
        player[:guess_elo]   = elos[player[:guess]]   || elos["1d"]
    end
    players
end

def cleanup(records, players)
    elos = setupelos(players)
    row = 1
    cleaned = []

    header = "record, date," \
        "white, white rank, white elo," \
        "black, black rank, black elo," \
        "winner"
    puts header if $options[:output][:records]
    records.each do |record|
        row += 1
        # skip incomplete records
        next STDERR.puts("#{row} nil date") if record[:date].nil?
        next STDERR.puts("#{row} not date") if !record[:date].respond_to?(:strftime)
        next STDERR.puts("#{row} no white") if record[:white].nil? || record[:white].empty?
        next STDERR.puts("#{row} no black") if record[:black].nil? || record[:black].empty?
        next STDERR.puts("#{row} no winner") if record[:winner].nil? || record[:winner].empty?

        # skip handicap
        next STDERR.puts("#{row} handicap #{record[:difference]}") if record[:difference] > $options[:handicap]

        # link player elo
        black_elos = elos.find { |elo| elo[:name] == record[:black]}
        next STDERR.puts("#{row} player #{record[:black]} not found") if black_elos.nil?
        white_elos = elos.find { |elo| elo[:name] == record[:white]}
        next STDERR.puts("#{row} player #{record[:white]} not found") if white_elos.nil?

        record[:row] = row
        record[:black_elos] = black_elos
        record[:white_elos] = white_elos
        cleaned << record

        info = "#{record[:row]}," \
            "#{record[:date].strftime("%Y%m%d")}," \
            "#{record[:white]},#{white_elos[:initial]},#{white_elos[:initial_elo]}," \
            "#{record[:black]},#{black_elos[:initial]},#{black_elos[:initial_elo]}," \
            "#{record[:winner]}+"

        puts info if $options[:output][:records]
    end
    cleaned
end

def whr(records, players, iterations=100)
    @whr = WholeHistoryRating::Base.new
    records.each do |record|
        extras = {
            :record => record
        }
        handicap = record[:difference] * $options[:weight]
        game = @whr.create_game(record[:black], record[:white], record[:winner], record[:date], handicap, extras)
    end
    @whr.players.each do |player|
        # STDERR.puts player[1]
    end
    @whr.iterate(iterations)
    @whr
end

def latest(ranks)
    puts "name, date, elo, uncertainty"
    data = []
    ranks.players.each do |player|
        last = @whr.player_by_name(player[0]).days.last
        data << {
            :name => player[0],
            :date => last.day,
            :elo => last.elo.round,
            :uncertainty => (last.uncertainty*100).round,
        }
    end
    sort = data.sort_by { |item| -item[:elo] }
    sort.each do |item|
        puts "#{item[:name]}, #{item[:date]}, #{item[:elo]}, #{item[:uncertainty]}"
    end
    sort
end

def chrono(ranks)
    puts "name, date, elo, uncertainty"
    ranks.players.each do |player|
        ratings = ranks.ratings_for_player(player[0])
        ratings.each do |rating|
            puts "#{player[0]}, #{rating[0]}, #{rating[1]}, #{rating[2]}"
        end
    end
end

def file(filename)
    records, players = import(filename)
    cleaned = cleanup(records, players)
    ranks = whr(cleaned, players)

    latest(ranks) if $options[:output][:latest]
    chrono(ranks) if $options[:output][:chrono]
end

def loop(folder)
    # puts "Loop: " + folder
    Dir.glob(folder + "/**/*.{xls,xlsx}").each do |filename|
        file(filename)
    end
end

parser = OptionParser.new do |options|
    options.banner = "Usage: ruby whr.rb [options] {file|folder}"
    # options.on("-v", "--verbose", "Run verbosely") do |v|
    #   $options[:verbose] = v
    # end
    options.on("", "--handicap HANDICAP", "Acceptable maximum handicap", Integer) do |handicap|
        $options[:handicap] = handicap.abs
    end
    options.on("", "--adjust WEIGHT", "Weight to adjust handicap difference", Float) do |weight|
        $options[:weight] = weight.abs
    end
    options.on("", "--records", "Output game records") do |records|
        $options[:output][:records] = true
    end
    options.on("", "--latest", "Output latest players elo") do |latest|
        $options[:output][:latest] = true
    end
    options.on("", "--chrono", "Output players elo in chrono order") do |chrono|
        $options[:output][:chrono] = true
    end
end
parser.parse!

if ARGV.size > 0
    if File.directory?(ARGV[0])
        loop(ARGV[0])
    elsif File.file?(ARGV[0])
        file(ARGV[0])
    else
        puts "#{ARGV[0]} not found"
    end
else
    puts parser
end
