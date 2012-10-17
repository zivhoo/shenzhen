require 'ostruct'

module Shenzhen::XcodeBuild
  class Info < OpenStruct; end

  class Error < StandardError; end
  class NilOutputError < Error; end

  class << self
    def info
      output = `xcodebuild -list 2> /dev/null`
      raise Error.new $1 if /^xcodebuild\: error\: (.+)$/ === output
      raise NilOutputError unless /\S/ === output

      lines = output.split(/\n/)
      hash = {}
      group = nil

      hash[:project] = lines.shift.match(/\"(.+)\"\:/)[1]

      lines.each do |line|
        if /\:$/ === line
          group = line.strip[0...-1].downcase.gsub(/\s+/, '_')
          hash[group] = []
          next
        end

        unless group.nil? or /\.$/ === line
          hash[group] << line.strip
        end
      end

      hash.each do |group, values|
        next unless Array === values
        values.delete("") and values.uniq! 
      end

      Info.new(hash)
    end

    def settings(flags = [])
      output = `xcodebuild #{flags.join(' ')} -showBuildSettings 2> /dev/null`
      raise Error.new $1 if /^xcodebuild\: error\: (.+)$/ === output
      raise NilOutputError unless /\S/ === output

      lines = output.split(/\n/)
      lines.shift

      hash = {}
      targetHash = {}
      lines.each do |line|
        # if line contains "Build settings for action build and target ${target}
        buildString = "Build settings for action build and target"
        matches = line.partition(buildString)
        if matches[1] == buildString
        # create new hash, add to targetHash with key target
          targetKey = matches[2].strip.chop
          hash = {}
          targetHash[targetKey] = hash
        else
        #else do what we've been doing
          key, value = line.split(/\=/).collect(&:strip)
          hash[key] = value
        end
      end
      targetHash
    end

    def version
      output = `xcodebuild -version`
      output.scan(/([\d\.?]+)/).flatten.first rescue nil
    end
  end
end
