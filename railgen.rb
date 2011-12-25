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

require 'haml'
require 'yaml'

class RailNetwork
  def self.load (data)
    network = self.new(data["name"] || "Rail Network")
    
    data["stations"].each do |n, st|
      network.add_station n, st["x"], st["z"], st["notes"]
    end
    
    data["lines"].each do |n, ln|
      line = network.add_line n, ln["name"], ln["direction"].to_sym, ln["flow"].to_sym, ln["type"].to_sym, ln["notes"]
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
  
  def to_s
    "#{name}"
  end
  
  def inspect
    "#<RailNetwork:#{object_id} #{name.inspect}>"
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
  
  def get_station (name)
    if name.is_a?(String)
      if @stations.has_key? (name)
        return @stations[name]
      else
        raise ArgumentError, "No station named #{name}"
      end
    elsif name.is_a?(Station)
      return name
    else
      raise TypeError, "name must be String or Station"
    end
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

LINE_TYPES = {
  :y12 => "Underground (Y = 12)",
  :y70 => "Aerial (Y = 70)",
  :surface => "Surface"
}

class Line
  attr_accessor :number, :name, :direction, :flow, :type, :notes, :stops
  
  def initialize (network, number, name, direction, flow, type, notes)
    @network = network
    @number = number
    @name = name
    @direction = direction
    @flow = flow
    @type = type
    @notes = notes
    @stops = []
  end
  
  def to_s
    "#{number} - #{name}"
  end
  
  def inspect
    "#<Line:#{object_id} #{to_s.inspect}>"
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
  
  def line_type
    LINE_TYPES[type]
  end
  
  def add_stop (stop, landing)
    stop = @network.get_station stop
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
  
  def to_s
    @name
  end
  
  def inspect
    "#<Station:#{object_id} #{name.inspect}>"
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
    @lines.sort_by {|ll| ll[0].number}.each do |ll|
      yield ll[0], ll[1]
    end
  end
end


class RenderContext
  def initialize (network)
    @network = network
    @stylesheet = "rail-style.css"
  end
end

def render_template(template_name, network)
  haml = Haml::Engine.new(File.read(template_name))
  haml.render RenderContext.new(network)
end
    

if __FILE__ == $0
  data = ARGV[0]
  html = ARGV[1]
  network = RailNetwork.from_file(data)
  File.open(html, 'w') do |io|
    io.write render_template("templates/listing.haml", network)
  end
end
