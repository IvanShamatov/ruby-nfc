# frozen_string_literal: true

require 'ffi'
require 'logger'
require_relative './libnfc'

module NFC
  class Error < StandardError; end

  @@context = nil
  # TODO
  @@logger = Logger.new($stderr)

  def self.version
    LibNFC.nfc_version
  end

  def self.context
    unless @@context
      ptr = FFI::MemoryPointer.new(:pointer, 1)
      LibNFC.nfc_init(ptr)
      @@context = ptr.read_pointer
    end
    @@context
  end

  def self.logger
    @@logger
  end
end
