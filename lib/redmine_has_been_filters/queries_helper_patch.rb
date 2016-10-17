require_dependency 'queries_helper'

module QueriesHelper
  include IssuesHelper

  unless instance_methods.include?(:column_content_with_has_been_filters)
    def column_content_with_has_been_filters(column, issue)
      if  column.name == :has_been_assigned_to
        get_has_been_assigned_users(column, issue, true)
      else
        column_content_without_has_been_filters(column, issue)
      end
    end
    alias_method_chain :column_content, :has_been_filters
  end

  unless instance_methods.include?(:csv_content_with_has_been_filters)
    def csv_content_with_has_been_filters(column, issue)
      if  column.name == :has_been_assigned_to
        get_has_been_assigned_users(column, issue, false)
      else
        csv_content_without_has_been_filters(column, issue)
      end
    end
    alias_method_chain :csv_content, :has_been_filters
  end

  def get_has_been_assigned_users(column, issue, html)
    users_ids = [issue.assigned_to_id]
    issue.journals.each do |journal|
      users_ids << journal.details.select { |i| i.prop_key == 'assigned_to_id' }.map(&:old_value)
      users_ids << journal.details.select { |i| i.prop_key == 'assigned_to_id' }.map(&:value)
    end
    users_ids.flatten!
    if users_ids.present?
      users_ids.uniq!
      users = User.where('id' => users_ids) #would be great to keep the order : ORDER BY FIELD('users'.'id', users_ids)
      users.collect { |v| html ? column_value(column, issue, v) : v.to_s }.compact.join(', ').html_safe if users
    else
      nil
    end
  end

end
