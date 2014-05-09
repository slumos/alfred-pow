require 'rexml/document'
require File.dirname(__FILE__) + '/lib/pow_app.rb'

class AlfredPow
  POWD_PATH = File.expand_path('~/Library/LaunchAgents/cx.pow.powd.plist')
  FW_PATH = File.expand_path('/Library/LaunchDaemons/cx.pow.firewall.plist')
  
  def self.create(source_path)
    app = PowApp.new({
      :name => File.basename(source_path),
      :source_path => source_path
    })
    if app.create!
      puts "#{app.name}.dev created successfully"
    else
      puts "Unable to create app"
    end
  end
  
  def self.browse(pow_path)
    if app = PowApp.find(pow_path)
      app.browse
      puts "#{app.name}.dev opened successfully"
    else
      puts "Unable to open app"
    end
  end
  
  def self.destroy(pow_path)
    if app = PowApp.find(pow_path)
      if app.destroy
        puts "#{app.name} destroyed successfully"
      else
        puts "Unable to destroy #{app.name}"
      end
    else
      puts "Couldn't find that app"
    end
  end
  
  def self.restart(pow_path)
    if app = PowApp.find(pow_path)
      app.restart
      puts "#{app.name}.dev restarted successfully"
    else
      puts "That app does not exist"
    end
  end
  
  def self.xip(pow_path)
    if app = PowApp.find(pow_path)
      puts app.xip_url
    else
      puts "That app does not exist"
    end
  end

  def self.load
    %x{launchctl load #{POWD_PATH}}
    %x{sudo launchctl load #{FW_PATH}}
    %x{sudo launchctl start cx.pow.firewall}
    puts 'launching pow'
  rescue
    puts "error #{$!}"
  end

  def self.unload
    if fw = File.read(FW_PATH)
      src, dst = fw.scan(/fwd .*?,(\d+).*?dst-port (\d+)/)[0]
    end

    src ||= 20559
    dst ||= 80

    %x{sudo unload #{FW_PATH}}
    rule = %x{sudo ipfw show}.scan(/^0*(\d+).*,20559.*dst-port 80/)[0][0]
    if rule
      %x{sudo ipfw del #{rule}}
    end

    %x{launchctl unload #{POWD_PATH}}
    puts 'stopping pow'
  rescue
    puts "error: #{$!}"
  end

  def self.list(keyword)
    found_apps = PowApp.search(keyword)
    doc = REXML::Document.new
    items = doc.add_element 'items'
    found_apps.each do |app|
      item = items.add_element('item', {'uid' => app.name, 'arg' => app.path})
      item.add_element('title').add_text(app.name)
      item.add_element('subtitle').add_text(app.url)
      item.add_element('icon', {'type' => ''})
    end
    puts doc.to_s
  end

end
