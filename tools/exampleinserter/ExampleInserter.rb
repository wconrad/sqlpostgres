#!/usr/bin/ruby1.8

#$: << File.dirname(__FILE__)
require 'tempfile'

class ExampleInserter

  def initialize(exampleFile)
    @exampleFile = exampleFile
  end

  def run
    output = getOutput
    exampleName = File.basename(@exampleFile).chomp(".rb")
    sourcePath, example = extractExample
    sourcePath = File.join(File.dirname(@exampleFile), sourcePath)
    example = undent(example)
    source = insertExample(sourcePath, exampleName, example, output)
    write(sourcePath, source)
  end

  private

  def getOutput
    open('|-') do |io|
      if io.nil?
        load @exampleFile
      else
        io.readlines
      end
    end
  end

  def read(filename)
    File.open(filename) do |file|
      file.readlines
    end
  end

  def write(filename, lines)
    temp = Tempfile.new(File.basename(__FILE__))
    temp.puts(lines)
    temp.close
    system("mv #{temp.path} #{filename}")
  end

  def extractExample
    inExample = false
    example = []
    sourcePath = nil
    exampleName = nil
    read(@exampleFile).each_with_index do |line, lineNumber|
      lineNumber += 1
      inExample = false if line =~ /# End example */
      example << line if inExample
      if line =~ /# Example:\s*(\S+)\s*$/
        sourcePath = $1
        if sourcePath.nil?
          raise "Error: Missing parameters on line #{lineNumber}"
        end
        inExample = true
      end
    end
    raise "No example found" if sourcePath.nil?
    [sourcePath, example]
  end


  def insertOutput(example, outputs)
    outputs = outputs.dup
    outputTag = "OUTPUT"
    rightMargin = 78
    example.collect do |line|
      if line =~ /^(.*?# *)#{outputTag}/
        output = outputs.shift.chomp
        prefix = $1
        chunkSize = rightMargin - line.index(outputTag)
        chunks = breakOutputIntoChunks(output, chunkSize)
        chunks.collect do |chunk|
          newLine = prefix + chunk
          prefix.gsub!(/[^#]/, ' ')
          newLine + "\n"
        end.join('')
      else
        line
      end
    end
  end

  def breakOutputIntoChunks(output, chunkSize)
    chunks = []
    while output.length > 0
      if output.length < chunkSize
        chunk = output
      else
        chunk = /^.?{0,#{chunkSize - 1}} /.match(output).to_a[0]
        chunk = chunk || output[0...chunkSize]
      end
      output = output[chunk.length..-1] || ''
      chunks << chunk
    end
    chunks
  end

  def undent(example)
    columnsToUndent = indentLevel(example)
    example.collect do |line|
      if line =~ /^ {#{columnsToUndent}}(.*\n)$/
        $1
      else
        line
      end
    end
  end

  def indentLevel(example)
    example.collect do |line|
      if line =~ /^(\s*)\S+/
        $1.length
      else
        nil
      end
    end.compact.min
  end

  def indent(example, indentLevel)
    example.collect do |line|
      "#{' ' * indentLevel}#{line}"
    end
  end

  def commentize(example)
    example.collect do |line|
      "#   #{line}"
    end
  end

  def insertExample(sourcePath, exampleName, example, outputs)
    inserted = false
    begin
      if sourcePath =~ /\.dbk$/
        source = read(sourcePath).join('')
        regex = /(<programlisting id=['"]#{exampleName}['"]>\n).*?(<\/programlisting>\n)/im
        source.gsub(regex) do |spaces|
          inserted = true
          $1 + insertOutput(example, outputs).join('') + $2
        end
      else
        source = read(sourcePath).join('')
        regex = /(( *)#\*\* *Example: *#{exampleName} *\n).*?(#\*\* *\n)/im
        source.gsub(regex) do |spaces|
          inserted = true
          indentLevel = $2.length
          $1 + insertOutput(indent(commentize(example), indentLevel), outputs).join('') + indent([$3], indentLevel).to_s
        end
      end
    ensure
      unless inserted
        raise "Example #{exampleName} not found in source #{sourcePath}" 
      end
    end
  end

end

def parseArgs
  @exampleFile = ARGV.shift
  unless ARGV.empty? && !@exampleFile.nil?
    puts "Usage: #{File.basename(__FILE__)} <example>"
    exit(1)
  end
end

if $0 == __FILE__
  parseArgs
  ExampleInserter.new(@exampleFile).run
end
