require_relative '../../cli/lib/rbld_reg_docker'
require_relative 'rbld_utils_shared'

module Rebuild
  module Registry
  module Docker

    [EntryNameParsingError,
     APIConnectionError].each do |c|
       describe c do
         include_examples 'rebuild error class'
       end
     end

    describe Entry do
      context 'created by name and tag' do
        let(:obj) { Entry.new( 'name', 'tag', 'remote' ) }

        it 'should know its name' do
          expect(obj.name).to be == 'name'
        end

        it 'should know its tag' do
          expect(obj.tag).to be == 'tag'
        end

        it 'should provide wildcard for searches' do
          expect(obj.wildcard).to be == 'rbe-name-rt-tag'
        end

        it 'should provide url repo for pulls and pushes' do
          expect(obj.url.repo).to be == 'remote/rbe-name-rt-tag'
        end

        it 'should provide url tag for pulls and pushes' do
          expect(obj.url.tag).to be == 'initial'
        end
      end

      context 'created by internal name' do
        let(:obj) { Entry.by_internal_name( 'rbe-name-rt-tag' ) }

        it 'should have correct name' do
          expect(obj.name).to be == 'name'
        end

        it 'should have correct tag' do
          expect(obj.tag).to be == 'tag'
        end
      end

      context 'created by a wrong internal name' do
        it 'should raise an exception' do
          expect { Entry.by_internal_name( 'wrong' ) }.to \
            raise_exception(EntryNameParsingError, 'Internal registry name parsing failed: wrong')
        end
      end

      context 'created by name without tag' do
        it 'should return name-only wildcard' do
          expect(Entry.new( 'name' ).wildcard).to be == 'rbe-name'
        end
      end

      context 'created by empty name without tag' do
        it 'should return global wildcard' do
          expect(Entry.new( '' ).wildcard).to be == 'rbe-'
        end
      end

      context 'created without name and tag' do
        it 'should return global wildcard' do
          expect(Entry.new.wildcard).to be == 'rbe-'
        end
      end
    end

    describe API do
      describe '#new' do
        let(:reg_class) { class_double('DockerRegistry2') }

        it 'should connect to registry on construction' do
          expect(reg_class).to receive(:connect).with('http://reg_url')
          API.new( 'reg_url', reg_class )
        end

        it 'should raise an exception on construction when registry is unaccessible' do
          allow(reg_class).to \
            receive(:connect).and_raise(DockerRegistry2::RegistryUnknownException)
          expect { API.new( 'reg_url', @reg_class ) }.to \
            raise_exception( APIConnectionError, 'Failed to access registry at reg_url' )
        end
      end

      describe '#search' do
        before :each do
          reg_class = class_double('DockerRegistry2')
          @reg_obj = instance_double('DockerRegistry2::Registry')
          allow(reg_class).to receive(:connect).and_return(@reg_obj)
          @api_obj = API.new( 'reg_url', reg_class )
        end

        it 'should search registry when requested' do
          expect(@reg_obj).to \
            receive(:search).with('rbe-name-rt-tag').and_return([])
          @api_obj.search('name', 'tag')
        end

        it 'should return search results' do
          allow(@reg_obj).to \
            receive(:search).and_return(['rbe-name1-rt-tag1',
                                         'rbe-name2-rt-tag2'])
          res = @api_obj.search()
          expect([res.size,
                  [res[0].name, res[0].tag],
                  [res[1].name, res[1].tag]]).to be ==
                 [2,
                  ['name1', 'tag1'],
                  ['name2', 'tag2']]
        end

        it 'should filter out non-rebuild images' do
          allow(@reg_obj).to receive(:search).and_return(['non-rebuild-repo'])
          expect(@api_obj.search().size).to be == 0
        end
      end

      describe '#publish' do
        let(:url) { Entry.new( 'name', 'tag', 'reg_url' ).url }
        let(:rbld_reg_obj) { API.new( 'reg_url',
                             class_double('DockerRegistry2').as_null_object ) }
        let(:img) { instance_double('Rebuild::Engine::NamedDockerImage') }

        it 'should tag, push and untag underlying docker image on publish' do
          api_obj = instance_double('Docker::Image').as_null_object
          allow(img).to receive(:api_obj).and_return(api_obj)

          expect(api_obj).to receive(:tag).ordered
          expect(api_obj).to receive(:push).ordered
          expect(api_obj).to receive(:remove).ordered

          rbld_reg_obj.publish('name', 'tag', img)
        end

        it 'should tag docker image on publish' do
          api_null_obj = instance_double('Docker::Image').as_null_object
          allow(img).to receive(:api_obj).and_return(api_null_obj)
          expect(api_null_obj).to receive(:tag).with(repo: url.repo, tag: url.tag)
          rbld_reg_obj.publish('name', 'tag', img)
        end

        it 'should push docker image on publish' do
          api_null_obj = instance_double('Docker::Image').as_null_object
          allow(img).to receive(:api_obj).and_return(api_null_obj)
          expect(api_null_obj).to receive(:push).with(nil, repo_tag: url.full)
          rbld_reg_obj.publish('name', 'tag', img)
        end

        it 'should untag docker image on publish' do
          api_null_obj = instance_double('Docker::Image').as_null_object
          allow(img).to receive(:api_obj).and_return(api_null_obj)
          expect(api_null_obj).to receive(:remove).with(name: url.full)
          rbld_reg_obj.publish('name', 'tag', img)
        end

        it 'should clean temporary tag on push failure' do
          api_null_obj = instance_double('Docker::Image').as_null_object
          allow(img).to receive(:api_obj).and_return(api_null_obj)
          allow(api_null_obj).to receive(:push).and_raise(StandardError)
          expect(api_null_obj).to receive(:remove).with(name: url.full)
          expect{ rbld_reg_obj.publish('name', 'tag', img) }.to \
            raise_error(StandardError)
        end

        it 'should not clean temporary tag on pre-push failure' do
          api_obj = instance_double('Docker::Image')
          allow(img).to receive(:api_obj).and_return(api_obj)
          allow(api_obj).to receive(:tag).and_raise(StandardError)
          expect(api_obj).not_to receive(:remove)
          expect{ rbld_reg_obj.publish('name', 'tag', img) }.to \
            raise_exception(StandardError)
        end

      end

      describe '#deploy' do
        let(:url) { Entry.new( 'name', 'tag', 'reg_url' ).url }

        before :each do
          reg_class = class_double('DockerRegistry2')
          expect(reg_class).to receive(:connect).and_return(nil)
          @rbld_reg_obj = Rebuild::Registry::Docker::API.new( 'reg_url', reg_class )
          @api_obj = class_double('Docker::Image')
          @img_obj = instance_double('Docker::Image')
        end

        it 'should pull corresponding docker image on deploy' do
          expect(@api_obj).to \
            receive(:create).
            with(fromImage: url.full).
            and_return(@img_obj.as_null_object)

          @rbld_reg_obj.deploy('name', 'tag', @api_obj) {}
        end

        it 'should delete remote tag from the pulled image' do
          allow(@api_obj).to receive(:create).and_return(@img_obj)
          expect(@img_obj).to receive(:remove).with(name: url.full)

          @rbld_reg_obj.deploy('name', 'tag', @api_obj) {}
        end

        it 'should yield pulled image to the caller' do
          allow(@api_obj).to receive(:create).and_return(@img_obj.as_null_object)

          @rbld_reg_obj.deploy('name', 'tag', @api_obj) do |img|
            expect(img).to be_eql @img_obj.as_null_object
          end
        end

        it 'should delete pulled image on block failure' do
          allow(@api_obj).to receive(:create).and_return(@img_obj)
          expect(@img_obj).to receive(:remove).with(name: url.full)

          expect{@rbld_reg_obj.deploy('name', 'tag', @api_obj) { raise StandardError }}.to \
            raise_exception(StandardError)
        end

      end
    end
  end
  end
end
