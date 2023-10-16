## 棋賽排名榜 Player Ranks

根據棋賽結果，以 [WHR](https://www.remi-coulom.fr/WHR/) 算法計算棋手的排名榜。 Based on game records
stored in EXCEL, to calculate player ranks by [WHR](https://www.remi-coulom.fr/WHR/) algorithm.

### 安裝 Install ruby [for macOS](https://www.ruby-lang.org/en/documentation/installation/#homebrew)
```bash
brew install ruby
```

### 安裝 Install gems
```bash
gem install optparse
gem install roo
gem install whole_history_rating
```

### 用法 Usage
```bash
ruby ./whr.rb
Usage: ruby whr.rb [options] {file|folder}
        --change VARIANCE            Variance of rating change over one time step
        --min-rank ELO               Acceptable player rank
        --handicap HANDICAP          Acceptable maximum handicap
        --elo DIFFERENCE             Acceptable maximum elo difference
        --adjust WEIGHT              Weight to adjust handicap difference
        --played GAMES               Minimum games played to be listed
        --record                     Output game records
        --latest                     Output latest players elo
        --chrono                     Output players elo in chrono order
```

### 測試 Test
```bash
mkdir -p test
cp ./data/Game-Record-20231010.xlsx ./test/

ruby ./whr.rb --latest test/Game-Record-20231010.xlsx > test/Rank-20231010-latest.csv
ruby ./whr.rb --chrono test/Game-Record-20231010.xlsx > test/Rank-20231010-chrono.csv
```

&copy; 2023 [Horace Ho](https://horaceho.com)
