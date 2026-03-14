# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_triage/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-triage'
  spec.version       = Legion::Extensions::CognitiveTriage::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Emergency cognitive prioritization for LegionIO'
  spec.description   = 'Triage system for cognitive overload. Classifies incoming demands by severity ' \
                       'and urgency, routes to appropriate processing queues, and manages cognitive ' \
                       'capacity under pressure.'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-triage'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-cognitive-triage'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-cognitive-triage/blob/master/README.md'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-cognitive-triage/blob/master/CHANGELOG.md'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-cognitive-triage/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ['lib']
end
