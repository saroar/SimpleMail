require "spec_helper"

RSpec.describe SimpleMail do
  it "has a version number" do
    expect(SimpleMail::VERSION).not_to be nil
  end

  it "has a version number" do
    expect(SimpleMail::VERSION).not_to be nil
  end

  describe SimpleMail do

    before(:each) do
      allow(SimpleMail).to receive(:deliver)
    end

    it "sends mail" do
      expect(SimpleMail).to receive(:deliver) do |mail|
        expect(mail.to).to eq [ 'joe@example.com' ]
        expect(mail.from).to eq [ 'sender@example.com' ]
        expect(mail.subject).to eq 'hi'
        expect(mail.body).to eq 'Hello, Joe.'
      end
      SimpleMail.mail(:to => 'joe@example.com', :from => 'sender@example.com', :subject => 'hi', :body => 'Hello, Joe.')
    end

    it "requires :to param" do
      expect{ SimpleMail.mail({}) }.to raise_error(ArgumentError)
    end

    it "doesn't require any other param" do
      expect{ SimpleMail.mail(:to => 'joe@example.com') }.to_not raise_error
    end

    it 'can list its available options' do
      expect( SimpleMail.permissable_options ).to include(:to, :body)
    end

    describe "builds a Mail object with field:" do
      it "to" do
        expect(SimpleMail.build_mail(:to => 'joe@example.com').to).to eq [ 'joe@example.com' ]
      end

      it "to with multiple recipients" do
        expect(SimpleMail.build_mail(:to => 'joe@example.com, friedrich@example.com').to).to eq [ 'joe@example.com', 'friedrich@example.com' ]
      end

      it "to with multiple recipients and names" do
        expect(SimpleMail.build_mail(:to => 'joe@example.com, "Friedrich Hayek" <friedrich@example.com>').to).to eq [ 'joe@example.com', 'friedrich@example.com' ]
      end

      it "to with multiple recipients and names in an array" do
        expect(SimpleMail.build_mail(:to => ['joe@example.com', '"Friedrich Hayek" <friedrich@example.com>']).to).to eq [ 'joe@example.com', 'friedrich@example.com' ]
      end

      it "cc" do
        expect(SimpleMail.build_mail(:cc => 'joe@example.com').cc).to eq [ 'joe@example.com' ]
      end

      it "reply_to" do
        expect(SimpleMail.build_mail(:reply_to => 'joe@example.com').reply_to).to eq [ 'joe@example.com' ]
      end

      it "cc with multiple recipients" do
        expect(SimpleMail.build_mail(:cc => 'joe@example.com, friedrich@example.com').cc).to eq [ 'joe@example.com', 'friedrich@example.com' ]
      end

      it "from" do
        expect(SimpleMail.build_mail(:from => 'joe@example.com').from).to eq [ 'joe@example.com' ]
      end

      it "bcc" do
        expect(SimpleMail.build_mail(:bcc => 'joe@example.com').bcc).to eq [ 'joe@example.com' ]
      end

      it "bcc with multiple recipients" do
        expect(SimpleMail.build_mail(:bcc => 'joe@example.com, friedrich@example.com').bcc).to eq [ 'joe@example.com', 'friedrich@example.com' ]
      end

      it "charset" do
        mail = SimpleMail.build_mail(:charset => 'UTF-8')
        expect(mail.charset).to eq 'UTF-8'
      end

      it "text_part_charset" do
        mail = SimpleMail.build_mail(:attachments => {"foo.txt" => "content of foo.txt"}, :body => 'test', :text_part_charset => 'ISO-2022-JP')
        expect(mail.text_part.charset).to eq 'ISO-2022-JP'
      end

      it "default charset" do
        expect(SimpleMail.build_mail(body: 'body').charset).to eq 'UTF-8'
        expect(SimpleMail.build_mail(html_body: 'body').charset).to eq 'UTF-8'
      end

      it "from (default)" do
        expect(SimpleMail.build_mail({}).from).to eq [ 'simple_mail@unknown' ]
      end

      it "subject" do
        expect(SimpleMail.build_mail(:subject => 'hello').subject).to eq 'hello'
      end

      it "body" do
        expect(SimpleMail.build_mail(body: 'What do you know, Joe?').body)
          .to eq 'What do you know, Joe?'
      end

      it "html_body" do
        expect(SimpleMail.build_mail(html_body: 'What do you know, Joe?').parts.first.body)
          .to eq 'What do you know, Joe?'
        expect(SimpleMail.build_mail(html_body: 'What do you know, Joe?').parts.first.content_type)
          .to eq 'text/html; charset=UTF-8'
      end

      it 'content_type' do
        expect(SimpleMail.build_mail(content_type: 'multipart/related').content_type)
          .to eq 'multipart/related'
      end

      it "date" do
        now = Time.now
        expect(SimpleMail.build_mail(:date => now).date).to eq DateTime.parse(now.to_s)
      end

      it "message_id" do
        expect(SimpleMail.build_mail(:message_id => '<abc@def.com>').message_id).to eq 'abc@def.com'
      end

      it "custom headers" do
        expect(SimpleMail.build_mail(:headers => {"List-ID" => "<abc@def.com>"})['List-ID'].to_s).to eq '<abc@def.com>'
      end

      it "sender" do
        expect(SimpleMail.build_mail(:sender => "abc@def.com")['Sender'].to_s).to eq 'abc@def.com'
      end

      it "utf-8 encoded subject line" do
        mail = SimpleMail.build_mail(:to => 'btp@foo', :subject => 'Café', :body => 'body body body')
        expect(mail['subject'].encoded).to match( /^Subject: =\?UTF-8/ )
      end

      it "attachments" do
        mail = SimpleMail.build_mail(:attachments => {"foo.txt" => "content of foo.txt"}, :body => 'test')
        expect(mail.parts.length).to eq 2
        expect(mail.parts.first.to_s).to match( /Content-Type: text\/plain/ )
        expect(mail.attachments.first.content_id).to eq "<foo.txt@#{Socket.gethostname}>"
      end

      it "suggests mime-type" do
        mail = SimpleMail.build_mail(:attachments => {"foo.pdf" => "content of foo.pdf"})
        expect(mail.parts.length).to eq 1
        expect(mail.parts.first.to_s).to match( /Content-Type: application\/pdf/ )
        expect(mail.parts.first.to_s).to match( /filename=foo.pdf/ )
        expect(mail.parts.first.content_transfer_encoding.to_s).to eq 'base64'
      end

      it "encodes xlsx files as base64" do
        mail = SimpleMail.build_mail(:attachments => {"foo.xlsx" => "content of foo.xlsx"})
        expect(mail.parts.length).to eq 1
        expect(mail.parts.first.to_s).to match( /Content-Type: application\/vnd.openxmlformats-officedocument.spreadsheetml.sheet/ )
        expect(mail.parts.first.to_s).to match( /filename=foo.xlsx/ )
        expect(mail.parts.first.content_transfer_encoding.to_s).to eq 'base64'
      end

      it "passes cc and bcc as the list of recipients" do
        mail = SimpleMail.build_mail(:to => ['to'], :cc => ['cc'], :from => ['from'], :bcc => ['bcc'])
        expect(mail.destinations).to eq  ['to', 'cc', 'bcc']
      end
    end

    describe "transport" do
      it "transports via smtp if no sendmail binary" do
        allow(SimpleMail).to receive(:sendmail_binary).and_return('/does/not/exist')
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:via => :smtp))
        SimpleMail.mail(:to => 'foo@bar')
      end

      it "defaults to sendmail if no via is specified and sendmail exists" do
        allow(File).to receive(:executable?).and_return(true)
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:via => :sendmail))
        SimpleMail.mail(:to => 'foo@bar')
      end

      describe "SMTP transport" do

        it "defaults to localhost as the SMTP server" do
          mail = SimpleMail.build_mail(:to => "foo@bar", :enable_starttls_auto => true, :via => :smtp)
          expect(mail.delivery_method.settings[:address]).to eq 'localhost'
        end

        it "enable starttls when tls option is true" do
          mail = SimpleMail.build_mail(:to => "foo@bar", :enable_starttls_auto => true, :via => :smtp)
          expect(mail.delivery_method.settings[:enable_starttls_auto]).to eq true
        end
      end
    end

    describe ":via option should over-ride the default transport mechanism" do
      it "should send via sendmail if :via => sendmail" do
        mail = SimpleMail.build_mail(:to => 'joe@example.com', :via => :sendmail)
        expect(mail.delivery_method.kind_of?(Mail::Sendmail)).to eq true
      end

      it "should send via smtp if :via => smtp" do
        mail = SimpleMail.build_mail(:to => 'joe@example.com', :via => :smtp)
        expect(mail.delivery_method.kind_of?(Mail::SMTP)).to eq true
      end

    end

    describe "sendmail binary location" do
      it "should default to /usr/sbin/sendmail if not in path" do
        allow(SimpleMail).to receive(:'`').and_return('')
        expect(SimpleMail.sendmail_binary).to eq '/usr/sbin/sendmail'
      end
    end

    describe "default options" do
      it "should use default options" do
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:from => 'noreply@simple_mail'))
        SimpleMail.options = { :from => 'noreply@simple_mail' }
        SimpleMail.mail(:to => 'foo@bar')
      end

      it "should merge default options with options" do
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:from => 'override@simple_mail'))
        SimpleMail.options = { :from => 'noreply@simple_mail' }
        SimpleMail.mail(:from => 'override@simple_mail', :to => "foo@bar")
      end

      it "should return the default options" do
        input = { :from => 'noreply@simple_mail' }
        SimpleMail.options = input
        output = SimpleMail.options
        expect(output).to eq input
      end
    end

    describe "override options" do
      it "should use the overide options" do
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:from => 'reply@simple_mail'))

        SimpleMail.override_options = { :from => 'reply@simple_mail' }
        SimpleMail.mail(:to => 'foo@bar')
      end

      it "should use an override option instead of a default options" do
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:from => 'reply@simple_mail.com'))

        SimpleMail.options = { :from => 'other_address@simple_mail.com' }
        SimpleMail.override_options = { :from => 'reply@simple_mail.com' }
        SimpleMail.mail(:to => 'foo@bar')
      end

      it "should use an override instead of a passed in value" do
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:from => 'reply@simple_mail.com'))

        SimpleMail.override_options = { :from => 'reply@simple_mail.com' }
        SimpleMail.mail(:to => 'foo@bar', :from => 'other_address@simple_mail.com')
      end

      it "should return the override options" do
        input = { :from => 'reply@simple_mail' }
        SimpleMail.override_options = input
        output = SimpleMail.override_options

        expect(output).to eq input
      end
    end

    describe "subject prefix" do
      after(:all) do
        SimpleMail.subject_prefix(false)
      end

      it "should prefix email subject line with the given text" do
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:subject => 'First: Second'))

        SimpleMail.subject_prefix('First: ')
        SimpleMail.mail(:to => 'foo@bar', :subject => 'Second')
      end

      it "should set the prefix as the subject if no subject is given" do
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:subject => 'First: '))

        SimpleMail.subject_prefix('First: ')
        SimpleMail.mail(:to => 'foo@bar')
      end
    end

    describe "append_inputs" do
      it "appends the options passed into Pany.mail to the body" do
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:body => "body/n {:to=>\"foo@bar\", :body=>\"body\"}"))

        SimpleMail.append_inputs

        SimpleMail.mail(:to => 'foo@bar', :body => 'body')
      end

      it "sets the options passed into Pany.mail as the body if one is not present" do
        expect(SimpleMail).to receive(:build_mail).with(hash_including(:body => "/n {:to=>\"foo@bar\"}"))

        SimpleMail.append_inputs

        SimpleMail.mail(:to => 'foo@bar')
      end

    end

    describe "content type" do
      context "mail with attachments, html_body and body " do
        subject(:mail) do
          SimpleMail.build_mail(
            :body => 'test',
            :html_body => 'What do you know, Joe?',
            :attachments => {"foo.txt" => "content of foo.txt"},
          )
        end

        it { expect(mail.parts.length).to eq 2 }
        it { expect(mail.parts[0].parts.length).to eq 2 }
        it { expect(mail.content_type.to_s).to include( 'multipart/mixed' ) }
        it { expect(mail.parts[0].content_type.to_s).to include( 'multipart/alternative' ) }
        it { expect(mail.parts[0].parts[0].to_s).to include( 'Content-Type: text/html' ) }
        it { expect(mail.parts[0].parts[1].to_s).to include( 'Content-Type: text/plain' ) }
        it { expect(mail.parts[1].to_s).to include( 'Content-Type: text/plain' ) }
      end
    end

    describe "additional headers" do
      subject(:mail) do
        SimpleMail.build_mail(
          :body => 'test',
          :html_body => 'What do you know, Joe?',
          :attachments => {"foo.txt" => "content of foo.txt"},
          :body_part_header => { content_disposition: "inline"},
          :html_body_part_header => { content_disposition: "inline"}
        )
      end

      it { expect(mail.parts[0].parts[0].to_s).to include( 'inline' ) }
      it { expect(mail.parts[0].parts[1].to_s).to include( 'inline' ) }

      context "when parts aren't present" do
        subject(:mail) do
          SimpleMail.build_mail(
            :body => 'test',
            :body_part_header => { content_disposition: "inline"},
            :html_body_part_header => { content_disposition: "inline"}
          )
        end

        it { expect(mail.parts).to be_empty }
        it { expect(mail.to_s).to_not include( 'inline' ) }
      end
    end

  end
end
