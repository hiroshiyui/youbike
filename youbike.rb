#!/usr/bin/env ruby
# encoding: utf-8

=begin
  YouBike rental stations data to JOSM XML, JSON, CSV file format converter
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
require 'slop'
require 'pp'

class Nodes
  COLUMNS = [:iid, :sv, :sd, :vtyp, :sno, :sna, :sip, :tot, :sbi, :sarea, :mday, :lat, :lng, :ar, :sareaen, :snaen, :aren, :nbcnt, :bemp, :act]
  FORMATS = ['osm', 'json', 'csv']

  def initialize(mode, opts)
    @options = opts
    @youbike_nodes = Array.new
    load_http if mode == 'get'
    load_file if mode == 'convert'
  end

  def save
    @format = FORMATS.include?(@options[:format]) ? @options[:format] : "osm"
    @output = (@options[:output].nil?) ? "youbike-#{Time.now.to_i}.#{@format}" : @options[:output]

    puts "Saving '#{@output}' ..."

    case @format
      when 'osm'
        self.to_osm
      when 'json'
        self.to_json
      when 'csv'
        self.to_csv
    end
  end

  def to_csv
    CSV.open(@output, "wb", {:force_quotes => true}) do |csv|
      csv << COLUMNS
      @youbike_nodes.each do |node|
        csv << node.values
      end
    end
  end

  def to_json
    File.open(@output, "wb") do |file|
      file << @youbike_nodes.to_json
    end
  end

  def to_osm
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.osm(:version => '0.6') {
        @youbike_nodes.each_with_index do |node, index|
          xml.node(:id => -index - 1, :visible => 'true', :lat => node['lat'], :lon => node['lng']) {
            xml.tag(:k => 'amenity', :v => 'bicycle_rental')
            xml.tag(:k => 'name', :v => node['sna'])
            xml.tag(:k => 'name:en', :v => node['snaen'])
            xml.tag(:k => 'name:zh', :v => node['sna'])
            xml.tag(:k => 'ref', :v => node['sno'])
            xml.tag(:k => 'capacity', :v => node['tot'])
            xml.tag(:k => 'network', :v => 'YouBike 微笑單車')
            xml.tag(:k => 'network:en', :v => 'YouBike')
            xml.tag(:k => 'network:zh', :v => '微笑單車')
          }
        end
      }
    end

    osm_xml = File.new(@output, 'w')
    osm_xml << builder.to_xml
    osm_xml.close
  end

  private
  def load_http
    @youbike_data = Net::HTTP.get(URI.parse("http://opendata.dot.taipei.gov.tw/opendata/gwjs_cityhall.json"))
    @youbike_nodes = JSON.parse(@youbike_data)['retVal']
  end

  def load_file
    abort if @options[:input].nil?
    abort unless File.readable?(@options[:input])

    @input = @options[:input]

    case File.extname(@input)
      when '.osm'
        Nokogiri::XML(File.open(@input).read).xpath('//node').each do |node|
          # mapping fields
          # :iid, :sv, :sd, :vtyp, :sno, :sna, :sip, :tot, :sbi, :sarea, :mday, :lat, :lng, :ar, :sareaen, :snaen, :aren, :nbcnt, :bemp, :act
          @youbike_nodes << Hash[ COLUMNS.zip [
            nil,
            nil,
            nil,
            nil,
            node.xpath("tag[@k='ref']").attr('v').to_s,
            node.xpath("tag[@k='name:zh']").attr('v').to_s,
            nil,
            node.xpath("tag[@k='capacity']").attr('v').to_s,
            nil,
            nil,
            nil,
            node['lat'],
            node['lon'],
            nil,
            nil,
            node.xpath("tag[@k='name:en']").attr('v').to_s,
            nil,
            nil,
            nil,
            nil] ]
        end
      when '.json'
        JSON.parse(File.open(@input).read).each do |node|
          @youbike_nodes << node.inject({}){ |h, (n,v)| h[n.to_sym] = v; h }
        end
      when '.csv'
        CSV.open(@input, options = {:headers => true}).each do |node|
          @youbike_nodes << node.to_hash.inject({}){ |h, (n,v)| h[n.to_sym] = v; h }
        end
    end
  end
end


# main
begin
  options = Slop.parse(help: true) do
    banner  "Usage: youbike.rb command [options]"
   
    command "get" do
      banner  "Usage: youbike.rb get [options]"
      on :t=, :format=, "Choose the output file format: osm, json, csv"
      on :o=, :output=, "Specify the output filename"
      run do |opts|
        nodes = Nodes.new(opts.config[:command], opts.to_hash(true))
        nodes.save
      end
    end

    command "convert" do
      banner  "Usage: youbike.rb convert [options]"
      on :t=, :format=, "Choose the output file format: osm, json, csv"
      on :i=, :input=, "Specify the local data source file"
      on :o=, :output=, "Specify the output filename"
      run do |opts|
        nodes = Nodes.new(opts.config[:command], opts.to_hash(true))
        nodes.save
      end
    end
  end

rescue Slop::MissingArgumentError
  puts "[Oops] Missing argument(s) :-("
end
