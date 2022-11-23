# frozen_string_literal: true

require 'podspec_editor'
require 'erb'

# create an editor
name = ARGV[0].to_s
podspec_path = ARGV[1].to_s
project_path = ARGV[2].to_s
template_file = ARGV[3].to_s

editor = PodspecEditor::Editor.new(spec_path: podspec_path)
ios = editor.spec.platforms[:ios]

pods = []

editor.spec.subspecs.each do |subspec|
  hash = PodspecEditor::Helper.openstruct_to_hash(subspec.dependencies)
  hash.each do |key, version|
    pods.append("  pod '#{key}'#{", '#{version[0]}'" unless version.empty?}")
  end
end

template = ERB.new(File.read(template_file))
podfile_str = template.result_with_hash({ plugin_name: name, ios_target: ios, pod_dependencies: pods.join("\n") })

File.open(File.join(project_path, 'Podfile'), 'w') do |line|
  line.puts podfile_str
end
