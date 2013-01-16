require "heroku/command/base"

# manage apps (create, destroy)
#
class Heroku::Command::Apps < Heroku::Command::Base

  # apps
  #
  # list your apps
  #
  #Example:
  #
  # $ heroku apps
  # === My Apps
  # myapp1
  # myapp2
  #
  # === Collaborated Apps
  # theirapp1   other@owner.name
  #
  def index
    validate_arguments!
    apps = api.get_apps.body
    unless apps.empty?
      my_apps, collaborated_apps = apps.partition do |app|
        app["owner_email"] == heroku.user
      end

      unless my_apps.empty?
        styled_header("My Apps")
        styled_array(my_apps.map { |app| app["name"] })
      end

      unless collaborated_apps.empty?
        styled_header("Collaborated Apps")
        styled_array(collaborated_apps.map { |app| [app["name"], app["owner_email"]] })
      end
    else
      display("You have no apps.")
    end
  end

  alias_command "list", "apps"

  # apps:info
  #
  # show detailed app information
  #
  # -r, --raw  # output info as raw key/value pairs
  #
  #Examples:
  #
  # $ heroku apps:info
  # === myapp
  # Git URL:   git@heroku.com:myapp.git
  # Repo Size: 5M
  # ...
  #
  # $ heroku apps:info --raw
  # git_url=git@heroku.com:myapp.git
  # repo_size=5000000
  # ...
  #
  def info
    validate_arguments!
    app_data = api.get_app(app).body

    unless options[:raw]
      styled_header(app)
    end

    addons_data = api.get_addons(app).body.map {|addon| addon["description"]}.sort
    collaborators_data = api.get_collaborators(app).body.map {|collaborator| collaborator["email"]}.sort
    collaborators_data.reject! {|email| email == app_data["owner_email"]}
    domain_name = (domains_data = api.get_domains(app).body) && domains_data.first && domains_data.first["domain"]

    if options[:raw]
      if domain_name
        app_data["domain_name"] = domain_name
      end
      app_data.keys.sort_by { |a| a.to_s }.each do |key|
        case key
        when :addons then
          hputs("addons=#{addons_data.join(",")}")
        when :collaborators then
          hputs("collaborators=#{collaborators_data.join(",")}")
        else
          hputs("#{key}=#{app_data[key]}")
        end
      end
    else
      data = {}

      unless addons_data.empty?
        data["Addons"] = addons_data
      end

      data["Collaborators"] = collaborators_data

      if app_data["create_status"] && app_data["create_status"] != "complete"
        data["Create Status"] = app_data["create_status"]
      end

      if app_data["cron_finished_at"]
        data["Cron Finished At"] = format_date(app_data["cron_finished_at"])
      end

      if app_data["cron_next_run"]
        data["Cron Next Run"] = format_date(app_data["cron_next_run"])
      end

      if app_data["database_size"]
        data["Database Size"] = format_bytes(app_data["database_size"])
      end

      data["Git URL"] = app_data["git_url"]

      if app_data["database_tables"]
        data["Database Size"].gsub!('(empty)', '0K') + " in #{quantify("table", app_data["database_tables"])}"
      end

      if app_data["dyno_hours"].is_a?(Hash)
        data["Dyno Hours"] = app_data["dyno_hours"].keys.map do |type|
          "%s - %0.2f dyno-hours" % [ type.to_s.capitalize, app_data["dyno_hours"][type] ]
        end
      end

      data["Owner Email"] = app_data["owner_email"]

      if app_data["repo_size"]
        data["Repo Size"] = format_bytes(app_data["repo_size"])
      end

      if app_data["slug_size"]
        data["Slug Size"] = format_bytes(app_data["slug_size"])
      end

      data["Stack"] = app_data["stack"]
      if data["Stack"] != "cedar"
        data.merge!("Dynos" => app_data["dynos"], "Workers" => app_data["workers"])
      end

      data["Web URL"] = app_data["web_url"]

      styled_hash(data)
    end
  end

  alias_command "info", "apps:info"

  # apps:create [NAME]
  #
  # create a new app
  #
  #     --addons ADDONS        # a comma-delimited list of addons to install
  # -b, --buildpack BUILDPACK  # a buildpack url to use for this app
  # -r, --remote REMOTE        # the git remote to create, default "heroku"
  # -s, --stack STACK          # the stack on which to create the app
  #
  #Examples:
  #
  # $ heroku apps:create
  # Creating floating-dragon-42... done, stack is bamboo-mri-1.9.2
  # http://floating-dragon-42.heroku.com/ | git@heroku.com:floating-dragon-42.git
  #
  # $ heroku apps:create -s cedar
  # Creating floating-dragon-42... done, stack is cedar
  # http://floating-dragon-42.herokuapp.com/ | git@heroku.com:floating-dragon-42.git
  #
  # # specify a name
  # $ heroku apps:create myapp
  # Creating myapp... done, stack is bamboo-mri-1.9.2
  # http://myapp.heroku.com/ | git@heroku.com:myapp.git
  #
  # # create a staging app
  # $ heroku apps:create myapp-staging --remote staging
  #
  def create
    name    = shift_argument
    validate_arguments!

    info    = api.post_app({ "name" => name, "stack" => options[:stack] }).body
    hprint("Creating #{info["name"]}...")
    begin
      if info["create_status"] == "creating"
        Timeout::timeout(options[:timeout].to_i) do
          loop do
            break if heroku.create_complete?(info["name"])
            hprint(".")
            sleep 1
          end
        end
      end
      hputs(" done, stack is #{info["stack"]}")

      (options[:addons] || "").split(",").each do |addon|
        addon.strip!
        action("Adding #{addon} to #{info["name"]}") do
          api.post_addon(name, addon)
        end
      end

      if buildpack = options[:buildpack]
        api.put_config_vars(name, "BUILDPACK_URL" => buildpack)
        display("BUILDPACK_URL=#{buildpack}")
      end

      hputs([ info["web_url"], info["git_url"] ].join(" | "))
    rescue Timeout::Error
      hputs("Timed Out! Check heroku status for known issues.")
    end

    create_git_remote(options[:remote] || "heroku", info["git_url"])
  end

  alias_command "create", "apps:create"

  # apps:rename NEWNAME
  #
  # rename the app
  #
  #Example:
  #
  # $ heroku apps:rename myapp-newname
  # http://myapp-newname.herokuapp.com/ | git@heroku.com:myapp-newname.git
  # Git remote heroku updated
  #
  def rename
    newname = shift_argument
    if newname.nil? || newname.empty?
      error("Usage: heroku apps:rename NEWNAME\nMust specify a new name.")
    end
    validate_arguments!

    action("Renaming #{app} to #{newname}") do
      api.put_app(app, "name" => newname)
    end

    app_data = api.get_app(newname).body
    hputs([ app_data["web_url"], app_data["git_url"] ].join(" | "))

    if remotes = git_remotes(Dir.pwd)
      remotes.each do |remote_name, remote_app|
        next if remote_app != app
        git "remote rm #{remote_name}"
        git "remote add #{remote_name} #{app_data["git_url"]}"
        hputs("Git remote #{remote_name} updated")
      end
    else
      hputs("Don't forget to update your Git remotes on any local checkouts.")
    end
  end

  alias_command "rename", "apps:rename"

  # apps:open
  #
  # open the app in a web browser
  #
  #Example:
  #
  # # opens the app in a browser
  # $ heroku apps:open
  #
  def open
    validate_arguments!

    app_data = api.get_app(app).body
    url = app_data["web_url"]
    hputs("Opening #{url}")
    require("launchy")
    Launchy.open(url)
  end

  alias_command "open", "apps:open"

  # apps:destroy
  #
  # permanently destroy an app
  #
  #Example:
  #
  # $ heroku apps:destroy -a myapp
  #
  def destroy
    @app = shift_argument || options[:app] || options[:confirm]
    validate_arguments!

    unless @app
      error("Usage: heroku apps:destroy --app APP\nMust specify APP to destroy.")
    end

    api.get_app(app) # fail fast if no access or doesn't exist

    message = "WARNING: Potentially Destructive Action\nThis command will destroy #{app} (including all add-ons)."
    if confirm_command(app, message)
      action("Destroying #{app} (including all add-ons)") do
        api.delete_app(app)
        if remotes = git_remotes(Dir.pwd)
          remotes.each do |remote_name, remote_app|
            next if app != remote_app
            git "remote rm #{remote_name}"
          end
        end
      end
    end
  end

  alias_command "destroy", "apps:destroy"
  alias_command "apps:delete", "apps:destroy"

end
