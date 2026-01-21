class Auth::TwitchController < ApplicationController
  def login
    scope = TwitchScopes.for_frontend_login.join(' ')
    render inline: oauth_post_form(scope)
  end

def bot_setup
  scope = TwitchScopes::BOT.join(' ')
  render inline: oauth_post_form(scope)
end


  private

  def oauth_post_form(scope)
    <<~HTML
      <html>
        <body onload="document.forms[0].submit()">
          <form method="post" action="/auth/twitch">
            <input type="hidden" name="scope" value="#{ERB::Util.html_escape(scope)}" />
            <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}" />
          </form>
        </body>
      </html>
    HTML
  end
end
