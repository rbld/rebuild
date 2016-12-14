require_relative '../../cli/lib/rbld_engine'
require_relative 'rbld_utils_shared'

module Rebuild::Engine

  [UnsupportedDockerService,
   EnvironmentIsModified,
   EnvironmentNotKnown,
   NoChangesToCommit,
   EnvironmentLoadFailure,
   EnvironmentSaveFailure,
   EnvironmentDeploymentFailure,
   EnvironmentAlreadyExists,
   EnvironmentNotFoundInTheRegistry,
   RegistrySearchFailed,
   EnvironmentPublishCollision,
   EnvironmentPublishFailure,
   EnvironmentCreateFailure].each do |c|
     describe c do
       include_examples 'rebuild error class'
     end
   end

  describe NamedDockerImage do
    let(:api_obj) { instance_double(Docker::Image) }
    let(:obj) { NamedDockerImage.new('imgname', api_obj) }

    it 'knows how to delete image name via API' do
      expect(api_obj).to receive(:remove).with(name: 'imgname')
      obj.remove!
    end

    it 'knows its internal name as identity' do
      expect(obj.identity).to be == 'imgname'
    end
  end

  describe NamedDockerContainer do
    let(:api_obj) { instance_double(Docker::Container) }
    let(:obj) { NamedDockerContainer.new('containername', api_obj) }

    it 'knows how to delete container name via API' do
      expect(api_obj).to receive(:delete).with(:force => true)
      obj.remove!
    end

    it 'knows how to commit a container' do
      expect(obj).to respond_to(:commit)
    end

    it 'knows how to flatten a container' do
      expect(obj).to respond_to(:flatten)
    end
  end

  describe NameFactory do
    let(:env) { OpenStruct.new(name: 'env', tag: 'tag') }
    let(:obj) { NameFactory.new(env) }

    it 'knows how to build environment identity' do
      expect(obj.identity.to_s).to be == 'rbe-env:tag'
    end

    it 'knows how to call intermediate image for environment modification' do
      expect(obj.rerun).to be == 'rbr-env-rt-tag:initial'
    end

    it 'knows how container with running environment is called' do
      expect(obj.running).to be == 'rbe-r-env-rt-tag'
    end

    it 'knows how container with environment modifications called' do
      expect(obj.modified).to be == 'rbe-d-env-rt-tag'
    end

    it 'knows host name for running environment' do
      expect(obj.hostname).to be == "#{env.name}-#{env.tag}"
    end

    it 'knows host name for modified environment' do
      expect(obj.modified_hostname).to be == "#{env.name}-#{env.tag}-M"
    end
  end

  describe Environment do
    it 'does not allow creation with new' do
      expect { Environment.new }.to raise_error(NoMethodError)
    end

    it 'may be created for images that follow naming convention of rebuild' do
      expect(Environment.from_image('rbe-name:tag', nil)).not_to be_nil
    end

    it 'may not be created for other images' do
      expect(Environment.from_image('name:tag', nil)).to be_nil
    end

    it 'knows if it is modified' do
      obj = Environment.from_image('rbe-name:tag', nil)
      expect { obj.attach_container('/rbe-d-name-rt-tag', Object.new) }.to \
        change { obj.modified? }.from(false).to(true)
    end

    context 'when created' do
      let(:obj) { Environment.from_image('rbe-name:tag', nil) }

      it 'knows its name' do
        expect(obj.name).to be == 'name'
      end

      it 'knows its tag' do
        expect(obj.tag).to be == 'tag'
      end

      it 'is equal to other objects with the same name and tag' do
        other = OpenStruct.new(name: 'name', tag: 'tag')
        expect(obj).to be == other
      end

      it 'is not equal to other objects with different name' do
        other = OpenStruct.new(name: 'name1', tag: 'tag')
        expect(obj).not_to be == other
      end

      it 'is not equal to other objects with different tag' do
        other = OpenStruct.new(name: 'name', tag: 'tag1')
        expect(obj).not_to be == other
      end

      it 'provides attribute reader for underlying docker image' do
        expect(obj).to respond_to(:img)
      end

      it 'provides attribute reader for underlying rerun docker image' do
        expect(obj).to respond_to(:rerun_img)
      end

      it 'provides attribute reader for container that runs this image' do
        expect(obj).to respond_to(:execution_container)
      end

      it 'provides attribute reader for container with image modifications' do
        expect(obj).to respond_to(:modification_container)
      end

      context 'attachment of container object' do
        it 'is allowed when name and tag match pattern for modified environment' do
          expect(obj.attach_container('/rbe-d-name-rt-tag', nil)).to be true
        end

        it 'is allowed when name and tag match pattern for running environment' do
          expect(obj.attach_container('/rbe-r-name-rt-tag', nil)).to be true
        end

        it 'is not allowed when name does not match' do
          expect(obj.attach_container('/rbe-d-name1-rt-tag', nil)).to be false
        end

        it 'is not allowed when tag does not match' do
          expect(obj.attach_container('/rbe-d-name-rt-tag1', nil)).to be false
        end

        it 'is not allowed when container name does not follow naming convention of rebuild' do
          expect(obj.attach_container('/non-rebuild-name', nil)).to be false
        end
      end

      context 'attachment of re-run image' do
        it 'is allowed when name and tag match' do
          expect(obj.attach_rerun_image('rbr-name-rt-tag:initial', nil)).to be true
        end

        it 'is not allowed when name does not match' do
          expect(obj.attach_rerun_image('rbr-name1-rt-tag:initial', nil)).to be false
        end

        it 'is not allowed when tag does not match' do
          expect(obj.attach_rerun_image('rbr-name-rt-tag1:initial', nil)).to be false
        end

        it 'is not allowed when container name does not follow naming convention of rebuild' do
          expect(obj.attach_rerun_image('non-rebuild-name:initial', nil)).to be false
        end
      end
    end
  end

  describe PresentEnvironments do
    before :each do
      stub_const("Rebuild::Engine::MockedDocker::Image", class_double(Docker::Image))
      stub_const("Rebuild::Engine::MockedDocker::Container", class_double(Docker::Container))

      @images = [
        OpenStruct.new(info: {'RepoTags' => ['rbe-name1:tag1',
                                             'rbr-name1-rt-tag1:initial']}),
        OpenStruct.new(info: {'RepoTags' => ['non-rebuild2']}),
        OpenStruct.new(info: {'RepoTags' => ['rbe-name3:tag3']}),
        OpenStruct.new(info: {'RepoTags' => ['non-rebuild4',
                                             'rbr-nameX-rt-tagX:initial']})
      ]

      @containers = [
        OpenStruct.new(info: {'Names' => ['/rbe-d-name1-rt-tag1']}),
        OpenStruct.new(info: {'Names' => ['/non-rebuild2']})
      ]

      allow(MockedDocker::Image).to receive(:all).and_return(@images)
      allow(MockedDocker::Container).to receive(:all).and_return(@containers)

      @obj = PresentEnvironments.new(MockedDocker)
    end

    it 'provides means to enumerate dangling images' do
      expect(MockedDocker::Image).to receive(:all).
        with( { filters: { label: ['re-build-environment=true'], dangling: [ 'true' ]}.to_json })

      @obj.dangling
    end

    it 'requests list of images with rebuild tag' do
      expect(MockedDocker::Image).to receive(:all).
        with( { filters: { label: ['re-build-environment=true'] }.to_json }).
        exactly(2).times
      PresentEnvironments.new(MockedDocker)
    end

    it 'requests list of containers with rebuild tag' do
      expect(MockedDocker::Container).to receive(:all).
        with( { all: true, filters: { label: ['re-build-environment=true'] }.to_json }).
        once
      PresentEnvironments.new(MockedDocker)
    end

    it 'holds list of existing environments' do
      expect(@obj.all.count).to be == 2
    end

    it 'knows if specific environment exists' do
      expect(@obj).to include(OpenStruct.new(name: 'name1', tag: 'tag1'))
    end

    it 'knows if specific environment does not exist' do
      expect(@obj).not_to include(OpenStruct.new(name: 'nameX', tag: 'tagX'))
    end

    it 'knows if specific environment is modified' do
      expect(@obj.find { |e| e == OpenStruct.new(name: 'name1', tag: 'tag1') }).to \
        be_modified
    end

    it 'knows docker API container object for a modified environment' do
      env = @obj.find { |e| e == OpenStruct.new(name: 'name1', tag: 'tag1') }
      expect(env.modification_container).not_to be_nil
    end

    it 'knows docker API re-run image object for a modified environment' do
      env = @obj.find { |e| e == OpenStruct.new(name: 'name1', tag: 'tag1') }
      expect(env.rerun_img).not_to be_nil
    end

    it 'knows how to search by environment name' do
      expect(@obj.get( OpenStruct.new(name: 'name1', tag: 'tag1') )).not_to be_nil
    end

    it 'knows how to refresh data after creation' do
      expect do
        allow(MockedDocker::Image).to receive(:all).
          and_return(OpenStruct.new(info: {}))
        @obj.refresh!
      end.to change{@obj.count}.from(2).to(0)
    end
  end

  describe API do
    it 'verifies docker API functionality on creation' do
      docker = class_double(Docker)

      allow(docker).to receive(:validate_version!).
        and_raise(Docker::Error::VersionError, 'msg')

      expect { API.new(docker, nil) }.to \
        raise_error(UnsupportedDockerService, 'Unsupported docker service: msg')
    end

  end
end
