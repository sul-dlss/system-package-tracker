set :deploy_to, '/home/reporting/server-reports'
server 'sulreports.stanford.edu', user: 'reporting',
                                              roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'production'
