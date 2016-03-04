class Report

  # Create a hash report of all servers and their installed packages.  If
  # given an optional hostname, limit the search to that one host.
  def installed_packages (hostname='')
    report = {}
    Server.all.order('hostname').each do |server|
      next if hostname != '' && server.hostname != hostname
      report[server.hostname] = {}

      # Go through each package.  In some cases (gems) there may be multiple
      # versions of a package on the machine.
      server.installed_packages.order('name').each do |package|
        name = package.name
        provider = package.provider

        # Create data structure if we've not yet encountered this provider or
        # package.
        if !report[server.hostname].key?(provider)
          report[server.hostname][provider] = {}
          report[server.hostname][provider][name] = []
        elsif !report[server.hostname][provider].key?(name)
          report[server.hostname][provider][name] = []
        end

        # Add the version.
        report[server.hostname][provider][name] << package.version
      end
    end

    return report
  end

  # Create a report on all servers that have advisories.  This should show
  # the servers with advisories, the names and versions of the affected
  # packages, and the version required to fix the advisory.  This returns a
  # hash that can be used for web or text display.
  def advisories (hostname='', search_package='')

    report = {}
    Server.all.order('hostname').each do |server|
      if hostname != ''
        next unless /#{hostname}/.match(server.hostname)
      end

      packages = {}
      server.installed_packages.order('name').each do |package|
        if search_package != ''
          next unless /#{search_package}/.match(package.name)
        end

        advisories = []
        package.advisories.order('name').uniq.each do |advisory|

          # Filter out fixed packages of everything but this package.  This
          # lets us see the version that has the fix.
          fixed = []
          if advisory.os_family == 'centos'
            advisory.fix_versions.split("\n").each do |fixed_package|
              m = /^(.+)-([^-]+)-([^-]+)\.(\w+)\.rpm$/.match(fixed_package)
              next unless m[1] == package.name
              next unless m[4] == package.arch
              fixed.push(m[2] + '-' + m[3])
            end
          else
            fixed = advisory.fix_versions.split("\n")
          end

          # Convert to a hash to drop into our results structure.
          advisory_report = advisory.as_json
          advisory_report['fix_versions_filtered'] = fixed.join(" ")
          advisories << advisory_report
        end

        # Now add any advisories to the record for this package/version.
        unless advisories.empty?
          unless packages.key?(package.name)
            packages[package.name] = {}
          end
          packages[package.name][package.version] = advisories
        end
      end

      # And if there were any packages, add them to the server.
      unless packages.empty?
        report[server.hostname] = packages
      end
    end

    return report
  end

  # Create a report on all servers that have advisories.  This should show
  # the servers with advisories, the names and versions of the affected
  # packages, and the version required to fix the advisory.  This returns a
  # hash that can be used for web or text display.
  def advisories_by_package (search_package='')

    report = {}
    Package.find_each do |package|
      if search_package != ''
        next unless /#{search_package}/.match(package.name)
      end

      next if package.servers.count == 0
      next if package.advisories.count == 0

      name = package.name
      version = package.version
      arch = package.arch
      provider = package.provider
      report[name] = {} unless report.key?(name)
      report[name][version] = {} unless report[name].key?(version)
      report[name][version][arch] = {} unless report[name][version].key?(arch)
      report[name][version][arch][provider] = {} unless report[name][version][arch].key?(name)

      # Add the number of advisories for this package/version.
      advisories = package.advisories.count
      report[name][version][arch][provider]['advisories'] = advisories

      # Add the list of servers that have this package installed.
      report[name][version][arch][provider]['servers'] = []
      package.servers.each do |server|
        report[name][version][arch][provider]['servers'].push(server.hostname)
      end
    end

    return report
  end

end
