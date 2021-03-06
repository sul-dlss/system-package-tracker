require 'rails_helper'

RSpec.describe Import::Packages::Gems, type: :model do
  describe "#update_source" do
    it "create git repo" do
      stub_const('Import::Packages::Gems::REPORTS_DIR', 'spec/data/tmp/')
      described_class.new.update_source
      testfile = 'spec/data/tmp/ruby-advisory-db/README.md'
      expect(File.exist?(testfile)).to eq(true)
    end
  end

  # Test loading the ruby advisories.
  describe "#import_advisories" do
    it "load known ruby advisories and check state" do
      stub_const('Import::Packages::Gems::REPORTS_DIR', 'spec/data/ruby-adv-test')
      stub_const('Import::Packages::Gems::RUBY_ADV_DIR', '/')
      described_class.new.import_advisories

      advisories = Advisory.where(os_family: 'gem').order('name')
      expect(advisories.size).to eq(14)

      # Make sure the first advisory matches what we expect.
      expect(advisories.first.name).to eq('2012-2660/82610')
      expect(advisories.first.description).to eq("Ruby on Rails contains a flaw related to the way ActiveRecord handles\nparameters in conjunction with the way Rack parses query parameters.\nThis issue may allow an attacker to inject arbitrary 'IS NULL' clauses in\nto application SQL queries. This may also allow an attacker to have the\nSQL query check for NULL in arbitrary places.\n")
      expect(advisories.first.issue_date).to eq('2012-05-31')
      expect(advisories.first.references).to eq('http://www.osvdb.org/show/osvdb/82610')
      expect(advisories.first.kind).to eq('Unknown')
      expect(advisories.first.severity).to eq('7.5')
      expect(advisories.first.os_family).to eq('gem')
      expect(advisories.first.title).to eq("Ruby on Rails ActiveRecord Class Rack Query Parameter Parsing SQL Query Arbitrary IS NULL Clause Injection")
      expect(advisories.first.cve).to eq('CVE-2012-2660')
      expect(advisories.first.upstream_id).to eq('82610')

      # activerecord should have four and one advisories, depending on version.
      packages = Package.where(name: 'activerecord').order('version')
      expect(packages.size).to eq(2)
      expect(packages.first.advisories.size).to eq(4)
      expect(packages.second.advisories.size).to eq(1)

      # rest-client should have two advisories.
      packages = Package.where(name: 'rest-client').order('version')
      expect(packages.size).to eq(1)
      expect(packages.first.advisories.size).to eq(2)
    end
  end
end
