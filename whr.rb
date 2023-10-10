require 'optparse'
require 'whole_history_rating'
require_relative 'xls'

include Xls

$options = {
    :verbose => false,
    :variance => 300.0, # default in whr
    :handicap => 9, # acceptable maximum handicap
    :weight => 100.0, # weight between each dan/kyu
    :output => {
        :record => false,
        :latest => false,
        :chrono => false,
        :played => 0,
    },
}

def whr(records, players, iterations=100)
    @whr = WholeHistoryRating::Base.new(:w2 => $options[:variance])
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

def record(records)
    puts "record,date," \
        "black,black rank,black elo," \
        "white,white rank,white elo," \
        "winner"

    records.each do |record|
        puts "#{record[:row]}," \
            "#{record[:date].strftime("%Y%m%d")}," \
            "#{record[:black]},#{record[:black_elos][:initial]},#{record[:black_elos][:initial_elo]}," \
            "#{record[:white]},#{record[:white_elos][:initial]},#{record[:white_elos][:initial_elo]}," \
            "#{record[:winner]}"
    end
end

def latest(ranks)
    puts "name,first,last,rank,elo,uncertainty,played,win,lost"
    data = []
    ranks.players.each do |player|
        days = @whr.player_by_name(player[0]).days
        any = days.first.won_games.first || days.first.lost_games.first
        elos = any.extras[:record][:black_elos] if player[0] == any.black_player.name
        elos = any.extras[:record][:white_elos] if player[0] == any.white_player.name
        played = days.sum{|day| day.won_games.count} + days.sum{|day| day.lost_games.count}
        data << {
            :name => player[0],
            :first => days.first.day,
            :last => days.last.day,
            :rank => elos[:initial],
            :elo => days.last.elo.round,
            :uncertainty => (days.last.uncertainty*100).round,
            :played => played,
            :won => days.sum{|day| day.won_games.count},
            :lost => days.sum{|day| day.lost_games.count},
        }
    end
    sort = data.sort_by { |item| -item[:elo] }
    sort.each do |item|
        puts "#{item[:name]},#{item[:first]},#{item[:last]}," \
            "#{item[:rank]},#{item[:elo]},#{item[:uncertainty]}," \
            "#{item[:played]},#{item[:won]},#{item[:lost]}" if item[:played] >= $options[:output][:played]
    end
    sort
end

def chrono(ranks)
    puts "name,date,elo,uncertainty,won,lost"
    data = []
    ranks.players.each do |player|
        # ratings = ranks.ratings_for_player(player[0])
        # ratings.each do |rating|
        #     puts "#{player[0]}, #{rating[0]}, #{rating[1]}, #{rating[2]}"
        # end
        days = @whr.player_by_name(player[0]).days
        days.each do |one|
            data << {
                :name => player[0],
                :date => one.day,
                :elo => one.elo.round,
                :uncertainty => (one.uncertainty*100).round,
                :won => one.won_games.count,
                :lost => one.lost_games.count,
            }
        end
    end
    data.each do |item|
        puts "#{item[:name]},#{item[:date]},#{item[:elo]},#{item[:uncertainty]},#{item[:won]},#{item[:lost]}"
    end
end

def file(filename)
    records, players = Xls::import(filename, $options)
    ranks = whr(records, players)
    record(records) if $options[:output][:record]
    latest(ranks) if $options[:output][:latest]
    chrono(ranks) if $options[:output][:chrono]
end

def folder(folder)
    Dir.glob(folder + "/**/*.{xls,xlsx}").each do |filename|
        file(filename)
    end
end

parser = OptionParser.new do |options|
    options.banner = "Usage: ruby whr.rb [options] {file|folder}"
    # options.on("-v", "--verbose", "Run verbosely") do |v|
    #   $options[:verbose] = v
    # end
    options.on("", "--change VARIANCE", "Variance of rating change over one time step", Float) do |variance|
        $options[:variance] = variance.abs
    end
    options.on("", "--handicap HANDICAP", "Acceptable maximum handicap", Integer) do |handicap|
        $options[:handicap] = handicap.abs
    end
    options.on("", "--adjust WEIGHT", "Weight to adjust handicap difference", Float) do |weight|
        $options[:weight] = weight.abs
    end
    options.on("", "--played GAMES", "Minimum games played to be listed", Integer) do |played|
        $options[:output][:played] = played.abs
    end
    options.on("", "--record", "Output game records") do
        $options[:output][:record] = true
    end
    options.on("", "--latest", "Output latest players elo") do
        $options[:output][:latest] = true
    end
    options.on("", "--chrono", "Output players elo in chrono order") do
        $options[:output][:chrono] = true
    end
end
parser.parse!

if ARGV.size > 0
    if File.directory?(ARGV[0])
        folder(ARGV[0])
    elsif File.file?(ARGV[0])
        file(ARGV[0])
    else
        puts "#{ARGV[0]} not found"
    end
else
    puts parser
end
