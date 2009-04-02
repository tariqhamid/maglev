
# Rake tasks for MagLev core developers.
#
# These tasks depend on the conventions used by the GemStone MagLev
# engineering team.

namespace :dev do
  require 'rakelib/dev.rb'

  desc "Stop server, install ../latest*, and reload primitives"
  task :'install-latest' => [:'dev:install-tgz', :'dev:loadmcz', :'dev:ensureprims']

  desc "Stop current server and install ../latest-product.tgz"
  task :'install-tgz' do
    tgz_file = '../latest-product.tgz'
    raise "Can't find product #{tgz_file}" unless File.exists?(tgz_file)

    Rake::Task[:'dev:ensure_stopped'].invoke
    ensure_std_directories
    rm_current_gemstone

    untar_product_to_gemstone tgz_file
    copy_extent
  end

  desc "Make sure the gemstone server is stopped."
  task :ensure_stopped do
    # We can't depend on the maglev:stop task, as that depends on there
    # being a gemstone/ directory, but it might not exist yet.  But if
    # there *is* a gemstone dir, then we may as well ensure there is no
    # instance running.
    if File.directory?(GEMSTONE)
      puts "=== Stopping the GemStone Server"
      Rake::Task['maglev:stop'].invoke
    else
      puts "=== No GemStone Server running"
    end
  end

  desc "Reload kernel.rb (primitives) and commit it"
  task :reloadprims => ['maglev:start'] do
    puts "=== reload primitives"
    run_topaz tc_reload_prims
  end

  desc "Ensure kernel.rb (primitives) is loaded and committed"
  task :ensureprims => ['maglev:start'] do
    puts "=== ensure primitives loaded"
    run_topaz tc_ensure_prims
  end

  desc "Load the mcz file ../latest.mcz and commit it."
  task :loadmcz => ['maglev:startparser', 'maglev:bootserver'] do
    puts "=== Load .mcz file: #{`ls -l ../latest.mcz`}"
    run_topaz tc_load_mcz
  end

  desc "Run the passing specs and the vm tests"
  task :smoke => [ 'dev:vm-tests', 'dev:passing' ]

  desc "Run the vm smoke tests"
  task :'vm-tests' do
    run_topaz tc_run_vmunit
    puts "Log files in log/vmunit*"
  end

  desc "Run the passing specs"
  task :'passing' do
    sh "spec/mspec/bin/mspec run -B passing.mspec"
    puts "Log files in log/vmunit*"
  end

  desc "Run the bm smoke tests"
  task :'bm-tests' do
    run_topaz tc_run_benchmarks
    puts "Log files in log/bench*"
  end

  desc "Clean up after a test install of rubygems"
  task :'clean-gems' do
    files = FileList['bin/maglev-gem', 'lib/ruby/site_ruby', 'lib/maglev']
    files.each { |fn| rm_r fn rescue nil }
  end

  desc "Stop the server, copy hotswap/* to data, restart the server"
  task :swap => [:'maglev:stopserver', :'dev:swapdb', :'maglev:startserver']

  task :swapdb do
    if server_running?
      puts "Must stop server before calling :swapdb"
    else
      puts "Copying data from hotswap -> data"
      cd MAGLEV_HOME do
        sh "cp hotswap/* data"
      end
    end
  end
end
