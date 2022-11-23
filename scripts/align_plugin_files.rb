# frozen_string_literal: true

# Source reference: https://stackoverflow.com/a/53208376
# Reference author: Shuangquan Wei
# Reference author profile: https://stackoverflow.com/users/5445143/shuangquan-wei

require 'xcodeproj'

def is_resource(file)
  extname = file[/\.[^.]+$/]
  ['.bundle', '.xcassets', '.xib', '.html', '.strings'].include?(extname)
end

def align_files(project, target, group)
  return unless File.exist?(group.real_path)

  Dir.foreach(group.real_path) do |entry|
    file_path = File.join(group.real_path, entry)
    if file_path.to_s.end_with?('.DS_Store', '.xcconfig')
      # Do nothing for this cases, they are configuration files
    elsif file_path.to_s.end_with?('.lproj')
      @variant_group = group.new_variant_group('Localizable.strings') if @variant_group.nil?
      string_file = File.join(file_path, 'Localizable.strings')
      file_reference = @variant_group.new_reference(string_file)
      target.add_resources([file_reference])
    elsif is_resource(entry)
      file_reference = group.new_reference(file_path)
      target.add_resources([file_reference])
    elsif !File.directory?(file_path)
      file_reference = group.new_reference(file_path)
      if file_path.to_s.end_with?('.m', '.mm', '.cpp', '.swift')
        target.add_file_references([file_reference])
      elsif file_path.to_s.end_with?('.framework') || file_path.to_s.end_with?('.xcframework') || file_path.to_s.end_with?('.a')
        target.frameworks_build_phases.add_file_reference(file_reference)
      end
    elsif File.directory?(file_path) && entry != '.' && entry != '..'
      sub_group = group.find_subpath(entry, true)
      sub_group.set_source_tree(group.source_tree)
      sub_group.set_path(File.join(group.real_path, entry))
      align_files(project, target, sub_group)
    end
  end
end

target_name = ARGV[0].to_s
project_path = "./#{target_name}/#{target_name}.xcodeproj"
project = Xcodeproj::Project.open(project_path)
group = project[target_name]

project.targets.each do |target|
  next unless target.name == target_name

  target.source_build_phase.files.to_a.map(&:remove_from_project)
  target.resources_build_phase.files.to_a.map(&:remove_from_project)
  group.clear
  align_files(project, target, group)
end

project.save
