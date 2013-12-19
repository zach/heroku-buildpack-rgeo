class LanguagePack::Ruby < LanguagePack::Base
  TRUTHY_STRING = /^(true|on|yes|1)$/
  RGEO_BASE_URL = "https://s3.amazonaws.com/camenischcreative/heroku-binaries/rgeo"

  def initialize(build_path, cache_path=nil)
    super(build_path, cache_path)
    @fetchers[:rgeo] = LanguagePack::Fetcher.new(RGEO_BASE_URL)
  end

  def binaries
    {geos: '3.3', proj: '4.8'}
  end

  def binary_names
    binaries.keys
  end

  alias_method :orig_default_config_vars, :default_config_vars
  def default_config_vars
    orig_default_config_vars.tap do |vars|
      vars['LD_LIBRARY_PATH'] = binary_names.map{|name| "/app/bin/#{name}/lib" }.join(':')
    end
  end

  def install_rgeo_binary(name, version)
    bin_dir = "bin/#{name}"
    FileUtils.mkdir_p bin_dir
    filename = "#{name}-#{version}.tgz"
    topic("Downloading #{name} from #{rgeo_url(filename)}")
    Dir.chdir(bin_dir) do |dir|
      @fetchers[:rgeo].fetch_untar("#{filename}.tgz")
    end
  end

  def pwd
    run('pwd').chomp
  end

  def pipe_debug(cmd)
    if ENV['DEBUG_BUILDPACK'] =~ TRUTHY_STRING
      topic "> #{cmd}"
      pipe  cmd
    end
  end

  def puts_debug(topic, string)
    if ENV['DEBUG_BUILDPACK'] =~ TRUTHY_STRING
      topic "puts #{topic}"
      puts  string
    end
  end

  alias_method :orig_compile, :compile
  def compile
    # Recompile all gems if 'requested' via environment variable
    # The user-env-compile labs feature must be enabled for this to work
    # See https://devcenter.heroku.com/articles/labs-user-env-compile
    cache_clear("vendor/bundle") if ENV['RECOMPILE_ALL_GEMS'] =~ TRUTHY_STRING


    binaries.each do |(name, version)|
      install_rgeo_binary(name, version)
    end

    binary_names.each do |name|
      pipe_debug "ls #{pwd}/bin/#{name}/include"
      pipe_debug "ls #{pwd}/bin/#{name}/lib"
    end
    lib_so_conf_dir = "#{pwd}/etc/ld.so.conf.d"
    FileUtils.mkdir_p(lib_so_conf_dir)
    binary_names.each do |name|
      File.open("#{lib_so_conf_dir}/#{name}.conf", 'w') do |file|
        file.write("/app/bin/#{name}/lib")
      end
    end
    ENV['BUNDLE_BUILD__RGEO'] = binary_names.map{|name| "--with-#{name}-dir=#{pwd}/bin/#{name}"}.join(' ')

    puts_debug 'ENV.to_hash.inspect', ENV.to_hash.inspect
    orig_compile
  end
end
