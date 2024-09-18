# frozen_string_literal: true
require_relative '../nfc'
require_relative './tag'
require_relative '../apdu/request'
require_relative '../apdu/response'

module IsoDep
   ISO_14443_4_COMPATIBLE = 0x20

   class Error < StandardError; end

   class Tag < NFC::Tag
     def self.match?(target)
       target[:nti][:nai][:btSak] & IsoDep::ISO_14443_4_COMPATIBLE > 0
     end

   def connect(&block)
        @reader.set_flag(:NP_AUTO_ISO14443_4, true)

       modulation = LibNFC::Modulation.new
       modulation[:nmt] = :NMT_ISO14443A
       modulation[:nbr] = :NBR_106

       nai_ptr = @target[:nti][:nai].pointer

       # abt + sak + szUidLen offset
       uid_ptr = nai_ptr + FFI.type_size(:uint8) * 3 + FFI.type_size(:size_t)

       res = LibNFC.nfc_initiator_select_passive_target(
          @reader.ptr,
         modulation,
         uid_ptr,
         uid.length,
         @target.pointer
       )

       raise IsoDep::Error, "Can't select tag: #{res}" unless res > 0
         super(&block)
       
         
       
   end

   def disconnect
       LibNFC.nfc_initiator_deselect_target(@reader.ptr) == 0
   end

       # Public: select application with give AID
       #
       # aid - Identifier of the application that should be selected
       #
       # Returns APDU::Response
   def select(aid)
       send_apdu("\x00\xA4\x04\x00#{aid.size.chr}#{aid}")
   end

       # Public: same as select but raises an APDU::Errno exception if
       # application not present on the card or SW is not equal to 0x9000
       #
       # aid - Identifier of the application that should be selected
       #
       # Returns APDU::Response
       # Raises APDU::Errno
   def select!(aid)
       select(aid).raise_errno!
   end

       # Public: Select application with given AID (Application Identifier)
       #
       # aid	-	Application Identifier of an applet located on a card
       #
       # Returns nothing.
       # Raises APDU::Errno if application with such AID doesn't exists on a card
   def select(aid)
       send_apdu!("\x00\xA4\x04\x00#{aid.size.chr}#{aid}")
   end

       # Public: Send APDU command to tag
       #
       # apdu	-	APDU command to send. see ISO/IEC 7816-4 or wiki for details.
       # 				APDU is a binary string that should
       #
       #
       # Returns APDU::Response object
       # Raises IsoDep::Error if card didn't respond
   def send_apdu(apdu)
       cmd = apdu
       cmd.force_encoding('ASCII-8BIT')
       command_buffer = FFI::MemoryPointer.new(:uint8, cmd.length)
       command_buffer.write_string_length(cmd, cmd.length)

       response_buffer = FFI::MemoryPointer.new(:uint8, 254)

       res_len = LibNFC.nfc_initiator_transceive_bytes(@reader.ptr,
                                                        command_buffer, cmd.length, response_buffer, 254, 0)

       raise IsoDep::Error, "APDU sending failed: #{res_len}" if res_len < 0

       APDU::Response.new(response_buffer.get_bytes(0, res_len).to_s)
   end

       # Public: Send APDU command to tag and raises APDU::Errno exception
       # if SW not equal to 0x9000
       #
       # apdu - APDU command to transmit to the tag
       #
       # Returns APDU::Response object
       # Raises APDU::Errno if SW is not equal to 0x9000
   def send_apdu!(apdu)
       send_apdu(apdu).raise_errno!
   end

   alias '<<' send_apdu
   end
end
