class Create<%= table_name.classify.pluralize %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %>, :force => true do |t|
      t.column "type",            :string,   :limit => 40
      t.column "position",        :integer
      t.column "name",            :text
<% unless use_original_name -%>      
      t.column "stored_name",     :text
      t.column "unique_key",      :string,   :limit => 32
<% end -%>
<% if parent_model.blank? -%>     
      t.column "attachable_type", :string,   :limit => 40
      t.column "attachable_id",   :integer
<% else -%>
      t.column "<%= parent_model%>_id", :integer
<% end -%>
      t.column "mime_type",       :string,   :limit => 40
      t.column "width",           :integer
      t.column "height",          :integer
      t.column "created_at",      :datetime
      t.column "updated_at",      :datetime
    end
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
