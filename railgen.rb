#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Railgen
#
# Copyright (C) 2011 Matthew Frazier.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'markaby'
require 'yaml'

class RailNetwork
  def self.load (data)
    network = self.new(data["name"] || "Rail Network")
    
    data["stations"].each do |n, st|
      network.add_station n, st["x"], st["z"], st["notes"]
    end
    
    data["lines"].each do |n, ln|
      line = network.add_line n, ln["name"], ln["direction"].to_sym, ln["notes"]
      ln["stops"].each do |stop|
        if stop.is_a?(Array)
          line.add_stop(stop[0], stop[1])
        else
          line.add_stop(stop, nil)
        end
      end
    end
    
    network
  end
  
  def self.from_file (filename)
    data = nil
    File.open filename do |io|
      data = YAML.load(io)
    end
    self.load(data)
  end
  
  attr_accessor :name, :stations, :lines
  
  def initialize (name)
    @name = name
    @stations = {}
    @lines = {}
  end
  
  def add_line (*args)
    line = Line.new(self, *args)
    @lines[line.number] = line
    line
  end
  
  def add_station (*args)
    station = Station.new(self, *args)
    @stations[station.name] = station
    station
  end
  
  def each_station
    stations.keys.sort.each do |code|
      yield @stations[code]
    end
  end
  
  def each_line
    lines.keys.sort.each do |number|
      yield @lines[number]
    end
  end
  
  def dump
    puts "== #{name} =="
    each_line do |line|
      puts "#{line.number} - #{line.name} (#{line.html_id})"
      puts "  ↓ = #{line.down_direction}, ↑ = #{line.up_direction}"
      line.each_stop do |st, landing|
        puts "  #{st.name} (#{st.coords}, #{landing || 'nil'})"
      end
      puts
    end
    
    each_station do |st|
      puts "#{st.name} (#{st.html_id})"
      puts "  #{st.notes || 'nil'}"
      st.each_line do |line, landing|
        puts "  #{line.number} - #{line.name} (#{landing || 'nil'})"
      end
      puts
    end
  end
end

# In the form [start to end, end to start]
DIRECTIONS = {
  :north => ["Northbound", "Southbound"],
  :east => ["Eastbound", "Westbound"],
  :south => ["Southbound", "Northbound"],
  :west => ["Westbound", "Eastbound"],
  :out => ["Outbound", "Inbound"],
  :in => ["Inbound", "Outbound"],
  :dextro => ["Dextro (Clockwise)", "Levo (Counterclockwise)"],
  :levo => ["Levo (Counterclockwise)", "Dextro (Clockwise)"]
}

class Line
  attr_accessor :number, :name, :direction, :notes
  
  def initialize (network, number, name, direction, notes)
    @network = network
    @number = number
    @name = name
    @direction = direction
    @notes = notes
    @stops = []
  end
  
  def html_id
    "line-#{number}"
  end
  
  def html_link
    "##{html_id}"
  end
  
  def down_direction
    DIRECTIONS[direction][0]
  end
  
  def up_direction
    DIRECTIONS[direction][1]
  end
  
  def add_stop (stop, landing)
    stop = @network.stations[stop] if stop.is_a?(String)
    @stops << [stop, landing]
    stop.add_line(self, landing)
  end
  
  def each_stop
    @stops.each do |s|
      yield s[0], s[1]
    end
  end
end


class Station
  attr_accessor :name, :x, :z, :notes, :lines
  
  def initialize (network, name, x, z, notes)
    @network = network
    @name = name
    @x = x
    @z = z
    @notes = notes
    @lines = []
  end
  
  def slug
    name.downcase.gsub(/[^a-z0-9]+/i, '-')
  end
  
  def html_id
    "station-#{slug}"
  end
  
  def html_link
    "##{html_id}"
  end
  
  def coords
    "x = #{x}, z = #{z}"
  end
  
  def add_line (line, landing)
    line = @network.lines[line] if line.is_a?(Integer)
    @lines << [line, landing]
  end
  
  def each_line
    @lines.sort {|ll| ll[0].number}.each do |ll|
      yield ll[0], ll[1]
    end
  end
end

def generate_html (network)
  Markaby::Builder.set :indent, 2
  builder = Markaby::Builder.new
  builder.html do
    head do
      title network.name
      link :rel => "stylesheet", :type => "text/css", :href => "rail-style.css"
    end
    body do
      h1 network.name
      
      div.lines! do
        h2 "Line Index"
        ul do
          network.each_line do |line|
            li {a "#{line.number} - #{line.name}", :href => line.html_link}
          end
        end
      end
      
      div.stations! do
        h2 "Station Index"
        ul do
          network.each_station do |station|
            li {a station.name, :href => station.html_link}
          end
        end
      end
      
      h2 "Lines"
      network.each_line do |line|
        div :id => line.html_id do
          h3 "#{line.number} - #{line.name}"
          ul do
            li.direction "↓ #{line.down_direction}"
          
            line.each_stop do |st, landing|
              li.station do
                a st.name, :href => st.html_link
                span.loc "(#{st.coords}#{landing ? ', ' : ''}#{landing})"
              end
            end
          
            li.direction "↑ #{line.up_direction}"
          end
        end
      end
      
      h2 "Stations"
      network.each_station do |station|
        div :id => station.html_id do
          h3 "#{station.name}"
          p.coords "(#{station.coords})"
          p.notes station.notes if station.notes
        
          ul do
            station.each_line do |line, landing|
              li.line do
                a "#{line.number} - #{line.name}", :href => line.html_link
                span.loc "(#{landing})" if landing
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  data = ARGV[0]
  html = ARGV[1]
  network = RailNetwork.from_file(data)
  File.open(html, 'w') do |io|
    io.write generate_html(network)
  end
end
