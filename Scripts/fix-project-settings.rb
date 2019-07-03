# Original script written by grpc-swift project authors
# Sourced from https://raw.githubusercontent.com/grpc/grpc-swift/master/fix-project-settings.rb

require 'xcodeproj'
project_path = ARGV[0]
project = Xcodeproj::Project.open(project_path)

# Fix indentation settings.
project.main_group.uses_tabs = '0'
project.main_group.tab_width = '2'
project.main_group.indent_width = '2'

# Set the `CURRENT_PROJECT_VERSION` variable for each config to ensure
# that the generated frameworks pass App Store validation (#291).
project.build_configurations.each do |config|
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1.0"
end

# Set each target's iOS deployment target to 13.0
project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
    if config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] then
      config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "io.grpc." + config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"]
    end
  end
end

project.save
