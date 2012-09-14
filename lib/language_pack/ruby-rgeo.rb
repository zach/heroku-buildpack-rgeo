class LanguagePack::Ruby < LanguagePack::Base
  def rgeo_url(filename = '')
    "https://s3.amazonaws.com/camenischcreative/heroku-binaries/rgeo/#{filename}"
  end

  # alias_method :orig_default_config_vars, :default_config_vars
  # def default_config_vars
  #   orig_default_config_vars.tap do |vars|
  #     vars['PATH'] << ''
  #   end
  # end

  def install_rgeo_binary(name)
    bin_dir = 'bin'
    FileUtils.mkdir_p bin_dir
    Dir.chdir(bin_dir) do |dir|
      pipe("curl #{rgeo_url}/#{name}.tgz -s -o - | tar xzf -")
    end
  end

  alias_method :orig_compile, :compile
  def compile
    orig_compile
    install_rgeo_binary('geos-3.3')
    install_rgeo_binary('proj-4.8')
  end
end