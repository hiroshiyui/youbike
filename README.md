# 臺北市公共自行車「YouBike 微笑單車」租賃站資料轉換程式

這是一個用 Ruby 寫的小程式，可將 YouBike 微笑單車租賃站資料轉換為 [JOSM file format](http://wiki.openstreetmap.org/wiki/JOSM_file_format), CSV, JSON 三種檔案格式，以便後續再利用。

## 使用方法

本程式遵循一般常見 Ruby 程式的部署方法，使用 Bundler 與 Gemfile 自動安裝必要元件。執行 <code>youbike.rb</code> 後，若過程無誤，則會在同樣位置產生 <code>youbike-export-<timestamp>.osm</code>, <code>youbike-export-<timestamp>.json</code>, <code>youbike-export-<timestamp>.csv</code> 檔案。
