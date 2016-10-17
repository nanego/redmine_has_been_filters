require_dependency 'issue_query'

class IssueQuery < Query

  self.available_columns << QueryColumn.new(:has_been_assigned_to, :sortable => lambda {User.fields_for_order_statement}, :groupable => true) if self.available_columns.select { |c| c.name == :has_been_assigned_to }.empty?

  unless instance_methods.include?(:initialize_available_filters_with_has_been_filters)
    def initialize_available_filters_with_has_been_filters
      initialize_available_filters_without_has_been_filters

      assigned_to_values = @available_filters["assigned_to_id"][:values]
      add_available_filter("has_been_assigned_to_id",
                           :type => :list_optional, :values => assigned_to_values
      ) unless assigned_to_values.empty?
    end
    alias_method_chain :initialize_available_filters, :has_been_filters
  end

  def sql_for_has_been_assigned_to_id_field(field, operator, value)

    if value.delete('me')
      value.push User.current.id.to_s
    end

    case operator
      when "*", "!*" # All / None
        boolean_switch = operator == "!*" ? 'NOT' : ''
        statement = operator == "!*" ? "#{Issue.table_name}.assigned_to_id IS NULL AND" : "(#{Issue.table_name}.assigned_to_id IS NOT NULL) OR"
        "(#{statement} #{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}, #{JournalDetail.table_name}" +
            " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND #{Journal.table_name}.id = #{JournalDetail.table_name}.journal_id AND #{Journal.table_name}.journalized_type = 'Issue' AND #{JournalDetail.table_name}.prop_key = 'assigned_to_id'))"
      when "=", "!"
        boolean_switch = operator == "!" ? 'NOT' : ''
        operator_switch = operator == "!" ? 'AND' : 'OR'

        assigned_to_empty = "#{Issue.table_name}.assigned_to_id IS NULL"
        assigned_to_id_statement = operator == "!" ? "#{assigned_to_empty} OR" : ''

        issue_attr_sql = "(#{assigned_to_id_statement} #{Issue.table_name}.assigned_to_id #{boolean_switch} IN (" + value.collect{|val| val.include?('function') ? "null" : "'#{self.class.connection.quote_string(val)}'"}.join(",") + "))"

        values = value.collect{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",")
        journal_condition1 = value.any? ? "#{JournalDetail.table_name}.value IN (" + values + ")" : "1=0"
        journal_condition2 = value.any? ? "#{JournalDetail.table_name}.old_value IN (" + values + ")" : "1=0"
        journal_sql = "#{boolean_switch} EXISTS (SELECT DISTINCT #{Journal.table_name}.journalized_id FROM #{Journal.table_name}, #{JournalDetail.table_name}" +
            " WHERE #{Issue.table_name}.id = #{Journal.table_name}.journalized_id AND #{Journal.table_name}.id = #{JournalDetail.table_name}.journal_id AND #{Journal.table_name}.journalized_type = 'Issue' AND #{JournalDetail.table_name}.prop_key = 'assigned_to_id'" +
            " AND (#{journal_condition1} OR #{journal_condition2}))"

        "((#{issue_attr_sql}) #{operator_switch} (#{journal_sql}))"
    end
  end

end
