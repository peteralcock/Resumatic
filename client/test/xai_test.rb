require "test_helper"

class XaiTest < Minitest::Test
  def setup
    VCR.use_cassette('retrieve_wsdl') do
      @xai = Xai.new(
        wsdl: 'https://deno.10x.ai/match/soap/processDocument?wsdl',
        account: 'demo_de_cv',
        username: 'demo_10x',
        password: ENV.fetch('TEXTKERNEL_KEY', 'secret')
      )
    end
    # sample resume from jsonresume.org
    @resume_path = 'test/fixtures/resume_richard_hendriks.pdf'
  end

  def test_that_it_has_a_version_number
    refute_nil ::Xai::VERSION
  end

  def test_it_parses_a_resume_from_local_file
    VCR.use_cassette('resume_richard_hendriks', record: :new_episodes) do
      assert_equal(
        @xai.extract!(@resume_path).dig(:resume, 'Profile', 'Personal').slice('FirstName', 'LastName').values.join(' '),
        'Richard Hendriks'
      )
    end
  end

  def test_it_parses_a_resuma_from_pulic_url
    VCR.use_cassette('resume_url_richard_hendriks', record: :new_episodes) do
      resume_path = 'https://www.dropbox.com/s/rlkwgood7wvbnn0/resume_richard_hendriks.pdf?dl=1'
      assert_equal(
        @xai.extract!(resume_path).dig(:resume, 'Profile', 'Personal').slice('FirstName', 'LastName').values.join(' '),
        'Richard Hendriks'
      )
    end
  end
end
