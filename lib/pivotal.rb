TOKEN = ENV["PIVOTAL_TOKEN"]
PROJECT_ID = ENV["PIVOTAL_PROJECT_ID"]

module PivotalApi
  class Task < ActiveResource::Base
    self.element_name = "task"
    self.site = "https://www.pivotaltracker.com/services/v4/projects/:project_id/stories/:story_id"
    headers['X-TrackerToken'] = TOKEN
    self.format = ActiveResource::Formats::XmlFormat
  end

  class Comment < ActiveResource::Base
    self.element_name = "comment"
    self.site = "https://www.pivotaltracker.com/services/v4/projects/:project_id/stories/:story_id"
    headers['X-TrackerToken'] = TOKEN
    self.format = ActiveResource::Formats::XmlFormat
  end
  class Iteration < ActiveResource::Base
    self.element_name = "iteration"
    self.site = "https://www.pivotaltracker.com/services/v4/projects/:project_id"
    headers['X-TrackerToken'] = TOKEN
    self.format = ActiveResource::Formats::XmlFormat
  end

  class Story < ActiveResource::Base
    self.element_name = "story"
    self.site = "https://www.pivotaltracker.com/services/v4/projects/:project_id"
    headers['X-TrackerToken'] = TOKEN
    self.format = ActiveResource::Formats::XmlFormat
    def tasks
      PivotalApi::Task.find(:all, params: {project_id: PROJECT_ID, story_id: id })
    end
    def comments
      PivotalApi::Comment.find(:all, params: {project_id: PROJECT_ID, story_id: id })
    end
  end

  class Activity < ActiveResource::Base
    self.element_name = "activity"
    self.site = "https://www.pivotaltracker.com/services/v4/projects/:project_id"
    headers['X-TrackerToken'] = TOKEN
    self.format = ActiveResource::Formats::XmlFormat
  end
end

class Pivotal < Context
  value :story_id
  def stories
    RbReadline.rl_clear_screen(0, 0);
    @model = PivotalApi::Story.find(:all, params: {project_id: PROJECT_ID, limit: 10})
    @model.each do |story|
      print "[##{story.id}] "
      puts story.description
    end
  end
  def backlog
    RbReadline.rl_clear_screen(0, 0);
    @model = PivotalApi::Iteration.find(:all, params: {project_id: PROJECT_ID, :scope => "current_backlog", offset: 100})
    @model.each do |iteration|
      iteration.stories.each do |story|
        print Rainbow(story.id).color("4d7c9e")
        print " "
        print story.name
        puts story.current_state
      end
    end
  end
  def story(story_id=nil)
    RbReadline.rl_clear_screen(0, 0);
    if story_id
      find(story_id)
    end
    puts
    puts Rainbow(@model.description).color("#253C64")
    @model.comments.each do |comment|
      print Rainbow(comment.author.person.name).yellow
      print ": "
      puts comment.text
    end
    @model.tasks.each do |task|
      if task.complete
        print Rainbow("[Done] ").green
      else
        print Rainbow("[TODO] ").red
      end
      puts task.description
    end
  end
  def find(story_id)
    puts "find #{story_id}"
    @model = PivotalApi::Story.find(story_id, params: {project_id: PROJECT_ID})
    self.story_id = story_id
    puts @model.name
    @model
  end
  def activity
    RbReadline.rl_clear_screen(0, 0);
    @model = PivotalApi::Activity.find(:all, params: {project_id: PROJECT_ID})
    @model.each do |activity|
      print activity.occurred_at.strftime("%a %H:%M"), " - "
      print activity.stories.map { |s| "[##{s.id}]"}.join(",") + " "
      puts activity.description
    end
  end
  def actions
    [:quit, :story, :activity, :stories, :backlog]
  end
end

#@stories = PivotalApi::Story.find(:all, params: {project_id: PROJECT_ID, filter: "label:\"nippo\""})
#puts @stories.to_yaml
#puts @stories.last.comments.to_yaml
