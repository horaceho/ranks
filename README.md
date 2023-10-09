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
        --handicap HANDICAP          Acceptable maximum handicap
        --records                    Output game records
        --latest                     Output latest players elo
        --chrono                     Output players elo in chrono order
```

### 例子 Example
```bash
ruby ./whr.rb --latest test/Game-Record-202310.xlsx > test/Rank-2023-latest.csv
ruby ./whr.rb --chrono test/Game-Record-202310.xlsx > test/Rank-2023-chrono.csv
```


&copy; 2023 [Horace Ho](https://horaceho.com)
