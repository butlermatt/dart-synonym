import os
from google.appengine.ext.webapp import template
from google.appengine.api import users
from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app

class MainPage(webapp.RequestHandler):
  def get(self):
    user = users.get_current_user()

    # only allow Google users to view this site
    if user and user.nickname().endswith("@google.com"):
      path = os.path.join(os.path.dirname(__file__), 'rosetta_stone.html')
      self.response.out.write(template.render(path,{}))
    else:
      self.redirect(users.create_login_url(self.request.uri))


application = webapp.WSGIApplication([('/', MainPage)], debug=True)

def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()