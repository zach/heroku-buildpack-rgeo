class LanguagePack::Helpers::BundlerWrapper
  class GemfileParseError < StandardError
    def initialize(error)
      msg = "There was an error parsing your Gemfile, we cannot continue\n"
      msg << error.message
      self.set_backtrace(error.backtrace)
      super msg
    end
  end

  VENDOR_URL         = LanguagePack::Base::VENDOR_URL                # coupling
  DEFAULT_FETCHER    = LanguagePack::Fetcher.new(VENDOR_URL)         # coupling
  BUNDLER_DIR_NAME   = LanguagePack::Ruby::BUNDLER_GEM_PATH          # coupling
  BUNDLER_TAR        = "#{LanguagePack::Ruby::BUNDLER_GEM_PATH}.tgz" # coupling
  BUNDLER_PATH       = File.expand_path("../../../../tmp/#{BUNDLER_DIR_NAME}", __FILE__)
  GEMFILE_PATH       = Pathname.new "./Gemfile"

  attr_reader   :bundler_path

  def initialize(options = {})
    @fetcher              = options[:fetcher]           || DEFAULT_FETCHER
    @bundler_path         = options[:bundler_path]      || BUNDLER_PATH
    @gemfile_path         = options[:gemfile_path]      || GEMFILE_PATH
    @gemfile_lock_path    = "#{@gemfile_path}.lock"
    ENV['BUNDLE_GEMFILE'] = @gemfile_path.to_s
    @unlock               = false
    @path                 = Pathname.new "#{@bundler_path}/gems/#{BUNDLER_DIR_NAME}/lib"
    fetch_bundler
    $LOAD_PATH << @path
    without_warnings do
      load @path.join("bundler.rb")
    end
  end

    def without_warnings(&block)
      orig_verb  = $VERBOSE
      $VERBOSE   = nil
      yield
    ensure
      $VERBOSE = orig_verb
    end

  def instrument(*args, &block)
    LanguagePack::Instrument.instrument(*args, &block)
  end

  def clean
    FileUtils.remove_entry_secure(bundler_path)
  end

  def ui
    Bundler.ui = Bundler::UI::Shell.new({})
  end

  def definition
    Bundler.definition(@unlock)
  rescue => e
    raise GemfileParseError.new(e)
  end

  def unlock
    @unlock = true
    yield
  ensure
    @unlock = false
  end

  def ruby_version
    unlock do
      definition.ruby_version
    end
  end

  def gemfile_lock?
    File.exist?('Gemfile') && File.exist?('Gemfile.lock')
  end

  def lockfile_parser
    @lockfile_parser ||= parse_gemfile_lock
  end

  private
  def fetch_bundler
    instrument 'fetch_bundler' do
      return true if Dir.exists?(bundler_path)
      FileUtils.mkdir_p(bundler_path)
      Dir.chdir(bundler_path) do
        @fetcher.fetch_untar(BUNDLER_TAR)
      end
    end
  end

  def parse_gemfile_lock
    instrument 'parse_bundle' do
      gemfile_contents = File.read(@gemfile_lock_path)
      Bundler::LockfileParser.new(gemfile_contents)
    end
  end
end
