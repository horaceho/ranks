require 'roo'

module Xls

    def import(filename, options)
        excel = Roo::Spreadsheet.open(filename)

        excel.default_sheet = excel.sheets[0] # Record
        records = excel.parse(
            date: /Date/,
            black: /Black|Player1/,
            white: /White|Player2/,
            handicap: /Handicap/,
            difference: /Difference/,
            winner: /Winner Side/,
            result: /Result/,
            organization: /Organization/,
            match: /Match/,
            round: /Round/,
            link: /OGS Link|Link/,
            remark: /Remark/,
            clean: true
        )

        excel.default_sheet = excel.sheets[1] # Player
        players = excel.parse(
            name: /Player/,
            initial: /Initial Rank/,
            flat: /Flat Rank|Initial Rank/,
            cert: /Cert Rank|Initial Rank/,
            guess: /Guess Rank|Initial Rank/,
            clean: true
        )

        cleaned = cleanup(records, players, options)

        return cleaned, players
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
            "na"  => 2100,
        }
        players.each do |player|
            player[:initial_elo] = elos[player[:initial]] || elos["1d"]
            player[:flat_elo]    = elos[player[:flat]]    || elos["1d"]
            player[:cert_elo]    = elos[player[:cert]]    || elos["1d"]
            player[:guess_elo]   = elos[player[:guess]]   || elos["1d"]
        end
        players
    end

    def cleanup(records, players, options)
        elos = setupelos(players)
        row = 1
        cleaned = []

        records.each do |record|
            row += 1
            record[:row] = row

            # skip incomplete records
            next STDERR.puts("#{row} nil date") if record[:date].nil?
            next STDERR.puts("#{row} not date") if !record[:date].respond_to?(:strftime)
            next STDERR.puts("#{row} no white") if record[:white].nil? || record[:white].empty?
            next STDERR.puts("#{row} no black") if record[:black].nil? || record[:black].empty?
            next STDERR.puts("#{row} no winner") if record[:winner].nil? || record[:winner].empty?

            # skip handicap
            next STDERR.puts("#{row} handicap #{record[:difference]}") if record[:difference] > options[:handicap]

            # link player elo
            black_elos = elos.find { |elo| elo[:name] == record[:black]}
            next STDERR.puts("#{row} player #{record[:black]} not found") if black_elos.nil?
            white_elos = elos.find { |elo| elo[:name] == record[:white]}
            next STDERR.puts("#{row} player #{record[:white]} not found") if white_elos.nil?

            record[:black_elos] = black_elos
            record[:white_elos] = white_elos

            # skip elo difference
            difference = (record[:white_elos][:initial_elo]-record[:black_elos][:initial_elo]).abs
            next STDERR.puts("#{row} elo difference #{difference}") if difference > options[:elo_diff]

            cleaned << record
        end
        cleaned
    end

end
