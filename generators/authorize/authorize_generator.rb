class AuthorizeGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.migration_template "migrate/create_authorizations.rb", "db/migrate", {:migration_file_name => 'create_authorizations'}
    end
  end
end
