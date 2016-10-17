Redmine::Plugin.register :redmine_has_been_filters do
  name 'Redmine Has Been Filters plugin'
  author 'Vincent ROBERT'
  description 'This is a plugin for Redmine which provides additional filters and columns to issues search screen'
  version '0.0.1'
  url 'https://github.com/nanego/redmine_customize_core_fields'
  author_url 'https://github.com/nanego'
end

# Custom patches
# require_dependency 'redmine_has_been_filters/hooks'
Rails.application.config.to_prepare do
  unless Rails.env.test? #Avoid breaking core tests (specially csv core tests including ALL columns)
    require_dependency 'redmine_has_been_filters/queries_helper_patch'
    require_dependency 'redmine_has_been_filters/issue_query_patch'
  end
  require_dependency 'redmine_has_been_filters/issues_pdf_helper_patch'
end
