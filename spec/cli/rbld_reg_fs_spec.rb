require_relative '../../cli/lib/rbld_reg_fs'
require_relative 'rbld_utils_shared'

module Rebuild
  module Registry
  module FS

    [FSLookupError].each do |c|
       describe c do
         include_examples 'rebuild error class'
       end
     end

  end
  end
end
