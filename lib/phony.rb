# frozen_string_literal: true

# NOTE We use Kernel.load here, as it's possible to redefine Phony via Phony::Config.

# Framework.
#
require_relative '../phony/config'
require_relative '../phony/vanity'
require_relative '../phony/local_splitters/fixed'
require_relative '../phony/local_splitters/regex'
require_relative '../phony/national_splitters/dsl'
require_relative '../phony/national_splitters/fixed'
require_relative '../phony/national_splitters/variable'
require_relative '../phony/national_splitters/regex'
require_relative '../phony/national_splitters/default'
require_relative '../phony/national_splitters/none'
require_relative '../phony/national_code'
require_relative '../phony/country'
require_relative '../phony/trunk_code'
require_relative '../phony/country_codes'
require_relative '../phony/dsl'

# Countries.
#
# The ones that need more space to define.
#
 require_relative '../phony/countries/argentina'
 require_relative '../phony/countries/austria'
 require_relative '../phony/countries/bangladesh'
 require_relative '../phony/countries/belarus'
 require_relative '../phony/countries/brazil'
 require_relative '../phony/countries/cambodia'
 require_relative '../phony/countries/croatia'
 require_relative '../phony/countries/china'
 require_relative '../phony/countries/georgia'
 require_relative '../phony/countries/germany'
 require_relative '../phony/countries/guinea'
 require_relative '../phony/countries/india'
 require_relative '../phony/countries/indonesia'
 require_relative '../phony/countries/ireland'
 require_relative '../phony/countries/italy'
 require_relative '../phony/countries/japan'
 require_relative '../phony/countries/kyrgyzstan'
 require_relative '../phony/countries/latvia'
 require_relative '../phony/countries/libya'
 require_relative '../phony/countries/malaysia'
 require_relative '../phony/countries/moldova'
 require_relative '../phony/countries/montenegro'
 require_relative '../phony/countries/myanmar'
 require_relative '../phony/countries/namibia'
 require_relative '../phony/countries/nepal'
 require_relative '../phony/countries/netherlands'
 require_relative '../phony/countries/pakistan'
 require_relative '../phony/countries/paraguay'
 require_relative '../phony/countries/russia_kazakhstan_abkhasia_south_ossetia'
 require_relative '../phony/countries/saudi_arabia'
 require_relative '../phony/countries/serbia'
 require_relative '../phony/countries/somalia'
 require_relative '../phony/countries/south_korea'
 require_relative '../phony/countries/sweden'
 require_relative '../phony/countries/taiwan'
 require_relative '../phony/countries/tajikistan'
 require_relative '../phony/countries/turkmenistan'
 require_relative '../phony/countries/vietnam'
 require_relative '../phony/countries/ukraine'
 require_relative '../phony/countries/united_kingdom'
 require_relative '../phony/countries/uruguay'
 require_relative '../phony/countries/zimbabwe'

# All other countries.
#
require_relative '../phony/countries'

# Phony is the main module and is generally used to process
# E164 phone numbers directly.
#
module Phony

  # Raised in case Phony can't normalize a given number.
  #
  # @example
  #   Phony.normalize("Fnork!") # Raises a Phony::NormalizationError.
  #
  class NormalizationError < ArgumentError
    def initialize
      super %Q{Phony could not normalize the given number. Is it a phone number?}
    end
  end
  
  # Raised in case Phony can't split a given number.
  #
  # @example
  #   Phony.split("Fnork!") # Raises a Phony::SplittingError.
  #
  class SplittingError < ArgumentError
    def initialize number
      super %Q{Phony could not split the given number. Is #{(number.nil? || number == '') ? 'it' : number.inspect} a phone number?}
    end
  end
  
  # Raised in case Phony can't format a given number.
  #
  # @example
  #   Phony.format("Fnork!") # Raises a Phony::FormattingError.
  #
  class FormattingError < ArgumentError
    def initialize
      super %Q{Phony could not format the given number. Is it a phone number?}
    end
  end

  # Phony uses a single country codes instance.
  #
  @codes = CountryCodes.instance

  class << self

    # Get the Country for the given CC.
    #
    # @param [String] cc A valid country code.
    #
    # @return [Country] for the given CC.
    #
    # @example Country for the NANP (includes the US)
    #   nanp = Phony['1']
    #   normalized_number = nanp.normalize number
    #
    def [] cc
      @codes[cc]
    end

    # Normalizes the given number into a digits-only String.
    #
    # Useful before inserting the number into a database.
    #
    # @param [String] phone_number An E164 number.
    # @param [Hash] options An options hash (With :cc as the only used key).
    #
    # @return [String] A normalized E164 number.
    #
    # @raise [Phony::NormalizationError] If phony can't normalize the given number.
    #
    # @example Normalize a Swiss number.
    #   Phony.normalize("+41 (044) 123 45 67") # => "41441234567"
    #
    # @example Normalize a phone number assuming it's a NANP number.
    #   Phony.normalize("301 555 0100", cc: '1') # => "13015550100"
    #
    def normalize phone_number, options = {}
      raise ArgumentError, "Phone number cannot be nil. Use e.g. number && Phony.normalize(number)." unless phone_number
      
      normalize! phone_number.dup, options
    end
    # A destructive version of {#normalize}.
    #
    # @see #normalize
    #
    # @param [String] phone_number An E164 number.
    # @param [Hash] options An options hash (With :cc as the only used key).
    #
    # @return [String] The normalized E164 number.
    #
    # @raise [Phony::NormalizationError] If phony can't normalize the given number.
    #
    # @example Normalize a Swiss number.
    #   Phony.normalize!("+41 (044) 123 45 67") # => "41441234567"
    #
    # @example Normalize a phone number assuming it's a NANP number.
    #   Phony.normalize!("301 555 0100", cc: '1') # => "13015550100"
    #
    def normalize! phone_number, options = {}
      @codes.normalize phone_number, options
    rescue
      raise NormalizationError.new
    end

    # Splits the phone number into pieces according to the country codes.
    #
    # Useful for manually processing the CC, NDC, and local pieces.
    #
    # @param [String] phone_number An E164 number.
    #
    # @return [Array<String>] The pieces of a phone number.
    #
    # @example Split a Swiss number.
    #   Phony.split("41441234567") # => ["41", "44", "123", "45", "67"]
    #
    # @example Split a NANP number.
    #   Phony.split("13015550100") # => ["1", "301", "555", "0100"]
    #
    def split phone_number
      raise ArgumentError, "Phone number cannot be nil. Use e.g. number && Phony.split(number)." unless phone_number
      
      split! phone_number.dup, phone_number
    end
    # A destructive version of {#split}.
    #
    # @see #split
    #
    # @param [String] phone_number An E164 number.
    #
    # @return [Array<String>] The pieces of the phone number.
    #
    # @example Split a Swiss number.
    #   Phony.split!("41441234567") # => ["41", "44", "123", "45", "67"]
    #
    # @example Split a NANP number.
    #   Phony.split!("13015550100") # => ["1", "301", "555", "0100"]
    #
    def split! phone_number, error_number = nil
      @codes.split phone_number
    rescue
      # NB The error_number (reference) is used because phone_number is destructively handled.
      raise SplittingError.new(error_number)
    end

    # Formats a normalized E164 number according to a country's formatting scheme.
    #
    # Absolutely needs a normalized E164 number.
    #
    # @param [String] phone_number A normalized E164 number.
    # @param [Hash] options See the README for a list of options.
    #
    # @return [Array<String>] The pieces of a phone number.
    #
    # @example Format a Swiss number.
    #   Phony.format("41441234567") # => "+41 44 123 45 67"
    #
    # @example Format a NANP number.
    #   Phony.format("13015550100") # => "+1 301 555 0100"
    #
    # @example Format a NANP number in local format.
    #   Phony.format("13015550100", :format => :local) # => "555 0100"
    #
    # @example Format a NANP number in a specific format.
    #   Phony.format("13015550100", :format => '%{cc} (%{trunk}%{ndc}) %{local}') # => "555 0100"
    #
    def format phone_number, options = {}
      raise ArgumentError, "Phone number cannot be nil. Use e.g. number && Phony.format(number)." unless phone_number
      format! phone_number.dup, options
    end
    # A destructive version of {#format}.
    #
    # @see #format
    #
    # Formats a normalized E164 number according to a country's formatting scheme.
    #
    # Absolutely needs a normalized E164 number.
    #
    # @param [String] phone_number A normalized E164 number.
    # @param [Hash] options See the README for a list of options.
    #
    # @return [Array<String>] The pieces of the phone number.
    #
    # @example Format a Swiss number.
    #   Phony.format!("41441234567") # => "+41 44 123 45 67"
    #
    # @example Format a NANP number.
    #   Phony.format!("13015550100") # => "+1 301 555 0100"
    #
    # @example Format a NANP number in local format.
    #   Phony.format!("13015550100", :format => :local) # => "555 0100"
    #
    def format! phone_number, options = {}
      @codes.format phone_number, options
    rescue
      raise FormattingError.new
    end
    alias formatted  format
    alias formatted! format!

    # Makes a plausibility check.
    #
    # If it returns false, it is not plausible.
    # If it returns true, it is unclear whether it is plausible,
    # leaning towards being plausible.
    #
    def plausible? number, hints = {}
      @codes.plausible? number, hints
    end

    # Returns true if there is a character in the number
    # after the first four numbers.
    #
    def vanity? phone_number
      @codes.vanity? phone_number.dup
    end

    # Converts any character in the vanity_number to its numeric representation.
    # Does not check if the passed number is a valid vanity_number, simply does replacement.
    #
    # @param [String] vanity_number A vanity number.
    #
    # @return [String] The de-vanitized phone number.
    #
    # @example De-vanitize a number.
    #   Phony.vanity_to_number("1-800-HELLOTHERE") # => "1-800-4355684373"
    #
    def vanity_to_number vanity_number
      @codes.vanity_to_number vanity_number.dup
    end

  end

end
