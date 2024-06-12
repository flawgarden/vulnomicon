#!/usr/bin/env python3

#
#   Based on create_per_cwe_files.py from the original Juliet package
#

import sys, os, shutil, glob, time, re

# add JulietCSharp directory to search path so we can use py_common
sys.path.append("../JulietCSharp")

import py_common
import update_csharp_templates


def copy_and_update_sln_template(sln_file_name, directory):

    # copy MainJuliet.sln into the this testcase dir
    main_sln = os.path.join(directory, sln_file_name)
    shutil.copy("Main.sln.template", main_sln)
    
    proj_guid = update_csharp_templates.build_guid(sln_file_name)
    # hardcoded value of TestCaseSupport GUID
    testcasesupport_csproj_guid = "{4CDBAE35-8CD1-4A0F-8912-B79D0BB43B83}"

    contents = py_common.open_file_and_get_contents(sln_file_name)
    
    contents = contents.replace("$CWE_PROJECT_GUID$", proj_guid)
    contents = contents.replace("$TCS_CSPROJ_GUID$", testcasesupport_csproj_guid)
    # fake path so the ".." in the template will work correctly
    contents = contents.replace("$SPLIT_DIR$", os.path.join("src", "testcases", "common") + os.sep)
    # we need to put the whole path to the .csproj file
    contents = contents.replace("$CWE$.csproj", "$CWE_CSPROJ_PATH$")
    
    py_common.write_file(sln_file_name, contents)


def get_project_guid(csproj_path):
    contents = py_common.open_file_and_get_contents(csproj_path)
    
    guid = re.search("<ProjectGuid>(.*?)</ProjectGuid>", contents)
    
    if not guid:
        py_common.print_with_timestamp("Could not find GUID for the following project: " + csproj_path)
        exit(3)
    
    return guid.group(1)


def get_csproj_info(dir_path, cwd):
    for f in os.listdir(dir_path):
        if f.endswith(".csproj"):
            csproj_path = os.path.join(dir_path, f)
            # keeping only the relative part of the path
            csproj_path = csproj_path[len(cwd) + 1:]
            return (csproj_path, get_project_guid(csproj_path))


def insert_cwe_projects(cwe_projects, main_sln):
    contents = py_common.open_file_and_get_contents(main_sln).split("\n")
    
    unchanged_top = contents[:5]
    declaration_template = "\n".join(contents[5:7])
    unchanged_mid = contents[7:15]
    compilation_template = "\n".join(contents[15:19])
    unchanged_end = contents[19:]
    
    project_declarations = []
    project_compilations = []
    for cwe in cwe_projects:
        path, guid = cwe

        common_name = "Juliet." + path.replace(os.sep, ".")

        decl = declaration_template
        decl = decl.replace("$CWE$", common_name)
        decl = decl.replace("$CWE_CSPROJ_PATH$", path)
        decl = decl.replace("$CWE_CSPROJ_GUID$", guid)

        comp = compilation_template
        comp = comp.replace("$CWE_CSPROJ_GUID$", guid)

        project_declarations.append(decl)
        project_compilations.append(comp)

    contents = unchanged_top \
        + project_declarations \
        + unchanged_mid \
        + project_compilations \
        + unchanged_end

    py_common.write_file(main_sln, "\n".join(contents))

    
def get_list_of_cwe_projects():
    cwe_regex = "CWE"
    testcases_path = os.path.join('src', 'testcases')
    cwes = []
    
    # get the CWE directories in testcases folder
    cwe_dirs = py_common.find_directories_in_dir(testcases_path, cwe_regex)

    # only allow directories
    cwe_dirs = filter(lambda x: os.path.isdir(x), cwe_dirs)
    
    cwd = os.getcwd()

    for dir in cwe_dirs:
        # check if the CWE is split into subdirectories
        if 's01' in os.listdir(dir):
            # get the list of subdirectories
            cwe_sub_dirs = py_common.find_directories_in_dir(dir, "^s\d.*")

            for sub_dir in cwe_sub_dirs:
                cwes.append(get_csproj_info(os.path.join(testcases_path, dir, sub_dir), cwd))
        else:
            cwes.append(get_csproj_info(os.path.join(testcases_path, dir), cwd))

    return cwes


if __name__ == "__main__":
    # check if ./testcases directory exists, if not, we are running
    # from wrong working directory
    if not os.path.exists(os.path.join('src', 'testcases')):
        py_common.print_with_timestamp("Wrong working directory; could not find testcases directory")
        exit(1)

    sln_file_name = "MainJuliet.sln"

    copy_and_update_sln_template(sln_file_name, "./")

    cwe_projects = get_list_of_cwe_projects()

    insert_cwe_projects(cwe_projects, sln_file_name)
