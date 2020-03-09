# frozen_string_literal: true

# NOTE We use Kernel.load here, as it's possible to redefine Phony via Phony::Config.

# Framework.
#
require '../phony/config.rb'
require '../phony/vanity.rb'
require '../phony/local_splitters/fixed.rb',
require '../phony/local_splitters/regex.rb',
require '../phony/national_splitters/dsl.rb',
require '../phony/national_splitters/fixed.rb',
require '../phony/national_splitters/variable.rb',
require '../phony/national_splitters/regex.rb',
require '../phony/national_splitters/default.rb',
require '../phony/national_splitters/none.rb',
require '../phony/national_code.rb',
require '../phony/country.rb',
require '../phony/trunk_code.rb',
require '../phony/country_codes.rb',
require '../phony/dsl.rb',

# Countries.
#
# The ones that need more space to define.
#
 require '../phony/countries/argentina.rb',
 require '../phony/countries/austria.rb',
 require '../phony/countries/bangladesh.rb',
 require '../phony/countries/belarus.rb',
 require '../phony/countries/brazil.rb',
 require '../phony/countries/cambodia.rb',
 require '../phony/countries/croatia.rb',
 require '../phony/countries/china.rb',
 require '../phony/countries/georgia.rb',
 require '../phony/countries/germany.rb',
 require '../phony/countries/guinea.rb',
 require '../phony/countries/india.rb',
 require '../phony/countries/indonesia.rb',
 require '../phony/countries/ireland.rb',
 require '../phony/countries/italy.rb',
 require '../phony/countries/japan.rb',
 require '../phony/countries/kyrgyzstan.rb',
 require '../phony/countries/latvia.rb',
 require '../phony/countries/libya.rb',
 require '../phony/countries/malaysia.rb',
 require '../phony/countries/moldova.rb',
 require '../phony/countries/montenegro.rb',
 require '../phony/countries/myanmar.rb',
 require '../phony/countries/namibia.rb',
 require '../phony/countries/nepal.rb',
 require '../phony/countries/netherlands.rb',
 require '../phony/countries/pakistan.rb',
 require '../phony/countries/paraguay.rb',
 require '../phony/countries/russia_kazakhstan_abkhasia_south_ossetia',
 require '../phony/countries/saudi_arabia.rb',
 require '../phony/countries/serbia.rb',
 require '../phony/countries/somalia.rb',
 require '../phony/countries/south_korea.rb',
 require '../phony/countries/sweden.rb',
 require '../phony/countries/taiwan.rb',
 require '../phony/countries/tajikistan.rb',
 require '../phony/countries/turkmenistan.rb',
 require '../phony/countries/vietnam.rb',
 require '../phony/countries/ukraine.rb',
 require '../phony/countries/united_kingdom.rb',
 require '../phony/countries/uruguay.rb',
 require '../phony/countries/zimbabwe'

# All other countries.
#
require '../phony/countries'

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
