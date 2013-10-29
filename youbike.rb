#!/usr/bin/env ruby
# encoding: utf-8

require 'csv'
require 'nokogiri'
require 'open-uri'
require 'net/http'

youbike_nodes = CSV.new(
  open(URI.escape("http://its.taipei.gov.tw/atis_index/aspx/Youbike.aspx?Mode=1")),
  options = {
    :col_sep => '_',
    :row_sep => '|',
    :headers => ["sno", "sna", "tot", "sbi", "sarea", "lat", "lng", "ar", "sareaen", "snaen", "aren", "row_sep"]
  } 
)

builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
  xml.osm(:version => '0.6') {
    youbike_nodes.each_with_index do |node, index|
      xml.node(:id => -index - 1, :visible => 'true', :lat => node['lat'], :lon => node['lng']) {
        xml.tag(:k => 'amenity', :v => 'bicycle_rental')
        xml.tag(:k => 'name', :v => "#{node['sna']} #{node['snaen']}")
        xml.tag(:k => 'name:en', :v => node['snaen'])
        xml.tag(:k => 'name:zh', :v => node['sna'])
        xml.tag(:k => 'ref', :v => node['sno'])
        xml.tag(:k => 'capacity', :v => node['tot'])
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

puts builder.to_xml

osm_xml = File.new('youbike.osm', 'w')
osm_xml << builder.to_xml
osm_xml.close
