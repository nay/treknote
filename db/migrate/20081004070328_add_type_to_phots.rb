class AddTypeToPhots < ActiveRecord::Migration
  def self.up
    execute("update photos set type = 'FilePhoto'")
  end

  def self.down
  end
end
