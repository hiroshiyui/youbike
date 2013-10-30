#!/usr/bin/env ruby
# encoding: utf-8

=begin
  YouBike rental stations data to JOSM XML file format converter
  Copyright (C) 2013  Huei-Horng Yo

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'csv'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'pp'

class Nodes
  COLUMNS = [:sno, :sna, :tot, :sbi, :sarea, :lat, :lng, :ar, :sareaen, :snaen, :aren]
  @@youbike_nodes = Array.new
  @@youbike_data = Net::HTTP.get(URI.parse("http://its.taipei.gov.tw/atis_index/aspx/Youbike.aspx?Mode=1"))
  @@youbike_data.force_encoding("UTF-8").split("|").sort.each do |node|
    @@youbike_nodes << Hash[COLUMNS.zip node.split("_")]
  end

  def self.to_csv
    CSV.open("youbike-export-#{Time.now.to_i}.csv", "wb") do |csv|
      csv << COLUMNS
      @@youbike_nodes.each do |node|
        csv << node.values
      end
    end
  end

  def self.to_json
    File.open("youbike-export-#{Time.now.to_i}.json", "wb") do |file|
      file << @@youbike_nodes.to_json
    end
  end

  def self.to_josm
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.osm(:version => '0.6') {
        @@youbike_nodes.each_with_index do |node, index|
          xml.node(:id => -index - 1, :visible => 'true', :lat => node[:lat], :lon => node[:lng]) {
            xml.tag(:k => 'amenity', :v => 'bicycle_rental')
            xml.tag(:k => 'name', :v => "#{node[:sna]} #{node[:snaen]}")
            xml.tag(:k => 'name:en', :v => node[:snaen])
            xml.tag(:k => 'name:zh', :v => node[:sna])
            xml.tag(:k => 'ref', :v => node[:sno])
            xml.tag(:k => 'capacity', :v => node[:tot])
            xml.tag(:k => 'network', :v => 'YouBike 微笑單車')
            xml.tag(:k => 'network:en', :v => 'YouBike')
            xml.tag(:k => 'network:zh', :v => '微笑單車')
            xml.tag(:k => 'operator', :v => '臺北市政府 Taipei City Government')
            xml.tag(:k => 'operator:en', :v => 'Taipei City Government')
            xml.tag(:k => 'operator:zh', :v => '臺北市政府')
          }
        end
      }
    end

    osm_xml = File.new("youbike-export-#{Time.now.to_i}.osm", 'w')
    osm_xml << builder.to_xml
    osm_xml.close
  end
end

Nodes.to_csv
Nodes.to_json
Nodes.to_josm
