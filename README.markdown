# BELGIAN 2050 CALCULATOR TOOL

A C version and ruby wrapper for the Belgian 2050 calcualtor

## GOTCHAS

Some versions have a special formula in 2050!B2 that the translator doesn't recognise. Just write 2050 in that cell and recompile.

Some tests fail for columns AN and AM on OUTPUT. I think this is due to rounding differences between excel and C.

## DEPENDENCIES

1. ruby 1.9.2 (including development headers)
2. basic c development headers

This has ONLY been tested on OSX and on Ubuntu 64 bit EC2 ami.
Grateful for reports from other platforms. 

In the util folder there is an example script that creates a new EC2 EMI, installs all the dependencies and then compiles the gem. It may be useful if you are trying to figure out the complete set of dependencies.

## INSTALLATION

Note that this compiles the underlying c code, which might take 10-20 minutes or so

    gem install belgium_2050_model
  
## UPDATING TO NEWER VERSIONS OF EXCEL MODEL

First of all, you need to be working on the github version of the code, not the rubygem:
    
    git clone http://github.com/decc/belgium_2050_model

Then put the new spreadsheet in spreadsheet/2050Model.xlsx

Then, from the top directory of the gem:
  
    bundle
    bundle exec rake
  
The next step is to check whether lib/belgium_2050_model/belgium_2050_model_result.rb and lib/belgium_2050_model/model_structure.rb need to be altered so that they
pick up the correct places in the underlying excel.
  
The final stage is to build and install the new gem:
    
    gem build belgium_2050_model.gemspec
    gem install belgium_2050_model-<version>.gem 

... where <version> is the version number of the gem file that was created in the folder.
  
Now follow the instructions in the twenty-fifty server directory in order to ensure that it is using this new version of the gem.
