# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'Manually Assigned Licenses' do
  # As a developer
  # I want to be able to override the licenses which license_finder finds
  # So that my dependencies all have the correct licenses

  let(:developer) { LicenseFinder::TestingDSL::User.new }

  specify 'are shown in cli after being added, and default license is not shown' do
    project = developer.create_ruby_app
    gem = developer.create_gem 'mislicensed_dep', license: 'Unknown'
    project.depend_on gem
    developer.execute_command 'license_finder licenses add mislicensed_dep Known'

    developer.run_license_finder
    expect(developer).not_to be_seeing_something_like /mislicensed_dep.*Unknown/
    expect(developer).to be_seeing_something_like /mislicensed_dep.*Known/
  end

  specify 'can be removed, revealing the default license for a dependency' do
    project = developer.create_ruby_app
    gem = developer.create_gem 'mislicensed_dep', license: 'Default'
    project.depend_on gem
    developer.execute_command 'license_finder licenses add mislicensed_dep Manual_license'

    developer.run_license_finder
    expect(developer).to be_seeing_something_like /mislicensed_dep.*Manual_license/

    developer.execute_command 'license_finder licenses remove mislicensed_dep Manual_license'

    developer.run_license_finder
    expect(developer).to be_seeing_something_like /mislicensed_dep.*Default/
  end

  specify 'can be assigned and removed by package version' do
    project = developer.create_ruby_app
    dep_a_gem = developer.create_gem 'dep_a', version: '2.0.0', license: 'Unknown'
    dep_b_gem = developer.create_gem 'dep_b', version: '3.0.0', license: 'Unknown'
    project.depend_on dep_a_gem
    project.depend_on dep_b_gem

    developer.execute_command 'license_finder licenses add dep_a GPL --version=1.0.0'
    developer.execute_command 'license_finder licenses add dep_a MIT --version=2.0.0'
    developer.execute_command 'license_finder licenses add dep_a GPL --version=3.0.0'

    developer.execute_command 'license_finder licenses add dep_b GPL --version=1.0.0'
    developer.execute_command 'license_finder licenses add dep_b GPL --version=2.0.0'
    developer.execute_command 'license_finder licenses add dep_b Apache-2.0 --version=3.0.0'

    developer.run_license_finder
    expect(developer).to be_seeing_line 'dep_a, 2.0.0, MIT'
    expect(developer).to be_seeing_line 'dep_b, 3.0.0, "Apache 2.0"'

    developer.execute_command 'license_finder licenses remove dep_a MIT --version=2.0.0'

    developer.run_license_finder
    expect(developer).to be_seeing_line 'dep_a, 2.0.0, Unknown'
    expect(developer).to be_seeing_line 'dep_b, 3.0.0, "Apache 2.0"'
  end
end
