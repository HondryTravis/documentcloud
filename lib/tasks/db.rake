namespace :db do

  desc "Back up the production database EBS as a snapshot on S3"
  task :backup => :environment do
    DC::Store::BackgroundJobs.backup_database
  end
  
  task :dump_structure do
    `pg_dump -U documentcloud -s -O dcloud_production > platform_structure.sql`
    `pg_dump -U documentcloud -a -t schema_migrations dcloud_production > schema_migrations.sql`
    `pg_dump -U documentcloud -s -O dcloud_analytics_production > platform_analytics_structure.sql`
  end

  desc "VACUUM ANALYZE the Postgres DB"
  task :vacuum_analyze => :environment do
    DC::Store::BackgroundJobs.vacuum_analyze
  end

  desc "Optimize the Solr Index"
  task :optimize_solr => :environment do
    DC::Store::BackgroundJobs.optimize_solr
  end

  desc "Apply db tasks in custom databases, for example  rake db:alter[db:migrate,test-es] applies db:migrate on the database defined as test-es in databases.yml"
  task :alter, [:task,:database] => :environment do |t, args|
    require 'activerecord'
    puts "Applying #{args.task} on #{args.database}"
    ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[args.database])
    Rake::Task[args.task].invoke
  end

  namespace :dev do
    [:start, :stop, :restart, :status].each do |cmd|
      task cmd do
        postgres_command cmd
      end
    end
  end

end

def postgres_command(cmd)
  sh "/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data #{cmd}"
end

