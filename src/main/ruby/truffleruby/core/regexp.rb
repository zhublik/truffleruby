# frozen_string_literal: true

# Copyright (c) 2014, 2019 Oracle and/or its affiliates. All rights reserved. This
# code is released under a tri EPL/GPL/LGPL license. You can use it,
# redistribute it and/or modify it under the terms of the:
#
# Eclipse Public License version 2.0, or
# GNU General Public License version 2, or
# GNU Lesser General Public License version 2.1.

# Copyright (c) 2007-2015, Evan Phoenix and contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of Rubinius nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

class Regexp
  IGNORECASE         = 1
  EXTENDED           = 2
  MULTILINE          = 4
  FIXEDENCODING      = 16
  NOENCODING         = 32
  DONT_CAPTURE_GROUP = 128
  CAPTURE_GROUP      = 256

  KCODE_NONE = (1 << 9)
  KCODE_EUC  = (2 << 9)
  KCODE_SJIS = (3 << 9)
  KCODE_UTF8 = (4 << 9)
  KCODE_MASK = KCODE_NONE | KCODE_EUC | KCODE_SJIS | KCODE_UTF8

  OPTION_MASK = IGNORECASE | EXTENDED | MULTILINE | FIXEDENCODING | NOENCODING | DONT_CAPTURE_GROUP | CAPTURE_GROUP

  ESCAPE_TABLE = Array.new(256)

  # Seed it with direct replacements
  i = 0
  while i < 256
    ESCAPE_TABLE[i] = i.chr
    i += 1
  end

  ESCAPE_TABLE[9]   = '\\t'
  ESCAPE_TABLE[10]  = '\\n'
  ESCAPE_TABLE[11]  = '\\v'
  ESCAPE_TABLE[12]  = '\\f'
  ESCAPE_TABLE[13]  = '\\r'
  ESCAPE_TABLE[32]  = '\\ '
  ESCAPE_TABLE[35]  = '\\#'
  ESCAPE_TABLE[36]  = '\\$'
  ESCAPE_TABLE[40]  = '\\('
  ESCAPE_TABLE[41]  = '\\)'
  ESCAPE_TABLE[42]  = '\\*'
  ESCAPE_TABLE[43]  = '\\+'
  ESCAPE_TABLE[45]  = '\\-'
  ESCAPE_TABLE[46]  = '\\.'
  ESCAPE_TABLE[63]  = '\\?'
  ESCAPE_TABLE[91]  = '\\['
  ESCAPE_TABLE[92]  = '\\\\'
  ESCAPE_TABLE[93]  = '\\]'
  ESCAPE_TABLE[94]  = '\\^'
  ESCAPE_TABLE[123] = '\\{'
  ESCAPE_TABLE[124] = '\\|'
  ESCAPE_TABLE[125] = '\\}'

  class << self
    alias_method :compile, :new
  end

  def self.try_convert(obj)
    Truffle::Type.try_convert obj, Regexp, :to_regexp
  end

  def self.convert(pattern)
    return pattern if pattern.kind_of? Regexp
    if pattern.kind_of? Array
      return union(*pattern)
    else
      return Regexp.quote(pattern.to_s)
    end
  end

  def self.compatible?(*patterns)
    encodings = patterns.map{ |r| convert(r).encoding }
    last_enc = encodings.pop
    encodings.each do |encoding|
      raise ArgumentError, "incompatible encodings: #{encoding} and #{last_enc}" unless Encoding.compatible?(last_enc, encoding)
      last_enc = encoding
    end
  end

  def self.last_match(index=nil)
    match = Truffle::RegexpOperations.last_match(TrufflePrimitive.caller_binding)
    if index
      index = Truffle::Type.coerce_to_int index
      match[index] if match
    else
      match
    end
  end

  def self.union(*patterns)
    case patterns.size
    when 0
      return %r/(?!)/
    when 1
      pattern = patterns.first
      case pattern
      when Array
        return union(*pattern)
      when Regexp
        return pattern
      else
        return Regexp.new(Regexp.quote(StringValue(pattern)))
      end
    else
      compatible?(*patterns)
      enc = convert(patterns.first).encoding
    end

    sep = '|'.encode(enc)
    str = ''.encode(enc)

    patterns = patterns.map do |pat|
      if pat.kind_of? Regexp
        pat
      else
        StringValue(pat)
      end
    end

    Truffle::RegexpOperations.union(str, sep, *patterns)
  end
  Truffle::Graal.always_split(method(:union))

  def initialize(pattern, opts=nil, lang=nil)
    if pattern.kind_of?(Regexp)
      opts = pattern.options
      pattern = pattern.source
    elsif pattern.kind_of?(Integer) or pattern.kind_of?(Float)
      raise TypeError, "can't convert #{pattern.class} into String"
    elsif opts.kind_of?(Integer)
      opts = opts & (OPTION_MASK | KCODE_MASK) if opts > 0
    elsif opts
      opts = IGNORECASE
    else
      opts = 0
    end

    code = lang[0] if lang
    opts |= NOENCODING if code == ?n or code == ?N

    compile pattern, opts # may be overridden by subclasses
  end

  def =~(str)
    unless str
      Truffle::RegexpOperations.set_last_match(nil, TrufflePrimitive.caller_binding)
      return nil
    end
    result = Truffle::RegexpOperations.match(self, str, 0)
    Truffle::RegexpOperations.set_last_match(result, TrufflePrimitive.caller_binding)

    result.begin(0) if result
  end

  def match(str, pos=0)
    unless str
      Truffle::RegexpOperations.set_last_match(nil, TrufflePrimitive.caller_binding)
      return nil
    end
    result = Truffle::RegexpOperations.match(self, str, pos)
    Truffle::RegexpOperations.set_last_match(result, TrufflePrimitive.caller_binding)

    if result && block_given?
      yield result
    else
      result
    end
  end

  def match?(str, pos = 0)
    Truffle::RegexpOperations.match(self, str, pos) != nil
  end

  def ===(other)
    if other.kind_of? Symbol
      other = other.to_s
    elsif !other.kind_of? String
      other = Truffle::Type.rb_check_convert_type other, String, :to_str
      unless other
        Truffle::RegexpOperations.set_last_match(nil, TrufflePrimitive.caller_binding)
        return false
      end
    end

    if match = match_from(other, 0)
      Truffle::RegexpOperations.set_last_match(match, TrufflePrimitive.caller_binding)
      true
    else
      Truffle::RegexpOperations.set_last_match(nil, TrufflePrimitive.caller_binding)
      false
    end
  end

  def eql?(other)
    return false unless other.kind_of?(Regexp)
    return false unless source == other.source
    (options & ~NOENCODING) == (other.options & ~NOENCODING)
  end

  alias_method :==, :eql?

  def inspect
    # the regexp matches any / that is after anything except for a \
    escape = source.gsub(%r!(\\.)|/!) { $1 || '\/' }
    str = "/#{escape}/#{option_to_string(options)}"
    str << 'n' if (options & NOENCODING) > 0
    str
  end

  def encoding
    TrufflePrimitive.encoding_get_object_encoding self
  end

  def ~
    line = Truffle::IOOperations.last_line(TrufflePrimitive.caller_binding)

    unless line.kind_of?(String)
      Truffle::RegexpOperations.set_last_match(nil, TrufflePrimitive.caller_binding)
      return nil
    end

    res = match(line)
    res ? res.begin(0) : nil
  end

  def casefold?
    (options & IGNORECASE) > 0 ? true : false
  end

  def match_from(str, count)
    return nil unless str
    search_region(str, count, str.bytesize, true)
  end

  def option_to_string(option)
    string = +''
    string << 'm' if (option & MULTILINE) > 0
    string << 'i' if (option & IGNORECASE) > 0
    string << 'x' if (option & EXTENDED) > 0
    string
  end

  #
  # call-seq:
  #    rxp.named_captures  => hash
  #
  # Returns a hash representing information about named captures of <i>rxp</i>.
  #
  # A key of the hash is a name of the named captures.
  # A value of the hash is an array which is list of indexes of corresponding
  # named captures.
  #
  #    /(?<foo>.)(?<bar>.)/.named_captures
  #    #=> {"foo"=>[1], "bar"=>[2]}
  #
  #    /(?<foo>.)(?<foo>.)/.named_captures
  #    #=> {"foo"=>[1, 2]}
  #
  # If there are no named captures, an empty hash is returned.
  #
  #    /(.)(.)/.named_captures
  #    #=> {}
  #
  def named_captures
    Hash[TrufflePrimitive.regexp_names(self)].transform_keys!(&:to_s)
  end

  #
  # call-seq:
  #    rxp.names   => [name1, name2, ...]
  #
  # Returns a list of names of captures as an array of strings.
  #
  #     /(?<foo>.)(?<bar>.)(?<baz>.)/.names
  #     #=> ["foo", "bar", "baz"]
  #
  #     /(?<foo>.)(?<foo>.)/.names
  #     #=> ["foo"]
  #
  #     /(.)(.)/.names
  #     #=> []
  #
  def names
    TrufflePrimitive.regexp_names(self).map { |x| x.first.to_s }
  end

end

class MatchData

  def offset(idx)
    out = []
    out << self.begin(idx)
    out << self.end(idx)
    out
  end

  def ==(other)
    other.kind_of?(MatchData) &&
      string == other.string  &&
      regexp == other.regexp  &&
      captures == other.captures
  end
  alias_method :eql?, :==

  def string
    TrufflePrimitive.match_data_get_source(self).dup.freeze
  end

  def names
    regexp.names
  end

  def named_captures
    names.collect { |name| [name, self[name]] }.to_h
  end

  def pre_match_from(idx)
    source = TrufflePrimitive.match_data_get_source(self)
    return source.byteslice(0, 0) if self.byte_begin(0) == 0
    nd = self.byte_begin(0) - 1
    source.byteslice(idx, nd-idx+1)
  end

  def begin(index)
    backref = if String === index || Symbol === index
                names_to_backref = Hash[TrufflePrimitive.regexp_names(self.regexp)]
                names_to_backref[index.to_sym].last
              else
                Truffle::Type.coerce_to(index, Integer, :to_int)
              end


    TrufflePrimitive.match_data_begin(self, backref)
  end

  def end(index)
    backref = if String === index || Symbol === index
                names_to_backref = Hash[TrufflePrimitive.regexp_names(self.regexp)]
                names_to_backref[index.to_sym].last
              else
                Truffle::Type.coerce_to(index, Integer, :to_int)
              end


    TrufflePrimitive.match_data_end(self, backref)
  end

  def collapsing?
    self.byte_begin(0) == self.byte_end(0)
  end

  def inspect
    str = "#<MatchData \"#{self[0]}\""
    idx = 0
    captures.zip(names) do |capture, name|
      idx += 1
      str << " #{name || idx}:#{capture.inspect}"
    end
    "#{str}>"
  end

  def values_at(*indexes)
    indexes.map { |i| self[i] }.flatten(1)
  end

  def to_s
    self[0]
  end
end

Truffle::KernelOperations.define_hooked_variable(
  :'$~',
  -> b { Truffle::RegexpOperations.last_match(b) },
  -> v, b { Truffle::RegexpOperations.set_last_match(v, b) })

Truffle::KernelOperations.define_hooked_variable(
  :'$`',
  -> b { match = Truffle::RegexpOperations.last_match(b)
         match.pre_match if match },
  -> { raise SyntaxError, "Can't set variable $`"},
  -> b { 'global-variable' if Truffle::RegexpOperations.last_match(b) })

Truffle::KernelOperations.define_hooked_variable(
  :"$'",
  -> b { match = Truffle::RegexpOperations.last_match(b)
         match.post_match if match },
  -> { raise SyntaxError, "Can't set variable $'"},
  -> b { 'global-variable' if Truffle::RegexpOperations.last_match(b) })

Truffle::KernelOperations.define_hooked_variable(
  :'$&',
  -> b { match = Truffle::RegexpOperations.last_match(b)
         match[0] if match },
  -> { raise SyntaxError, "Can't set variable $&"},
  -> b { 'global-variable' if Truffle::RegexpOperations.last_match(b) })

Truffle::KernelOperations.define_hooked_variable(
  :'$+',
  -> b { match = Truffle::RegexpOperations.last_match(b)
         match.captures.reverse.find { |m| !m.nil? } if match },
  -> { raise SyntaxError, "Can't set variable $+"},
  -> b { 'global-variable' if Truffle::RegexpOperations.last_match(b) })
