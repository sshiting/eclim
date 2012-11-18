/**
 * Copyright (C) 2012 - 2013 Eric Van Dewoestine
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package org.eclim.plugin.pydev.project;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.OptionBuilder;

import org.eclim.command.CommandLine;
import org.eclim.command.Error;
import org.eclim.command.Options;

import org.eclim.plugin.core.project.ProjectManager;

import org.eclim.util.CollectionUtils;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IProjectDescription;

import org.eclipse.core.runtime.NullProgressMonitor;

import org.python.pydev.core.IGrammarVersionProvider;
import org.python.pydev.core.IInterpreterInfo;
import org.python.pydev.core.IInterpreterManager;

import org.python.pydev.plugin.PydevPlugin;

import org.python.pydev.plugin.nature.PythonNature;

/**
 * Implementation of {@link ProjectManager} for pydev projects.
 *
 * @author Eric Van Dewoestine
 */
public class PydevProjectManager
  implements ProjectManager
{
  @SuppressWarnings("static-access")
  @Override
  public void create(IProject project, CommandLine commandLine)
    throws Exception
  {
    String[] args = commandLine.getValues(Options.ARGS_OPTION);
    GnuParser parser = new GnuParser();
    org.apache.commons.cli.Options options = new org.apache.commons.cli.Options();
    options.addOption(
        OptionBuilder.hasArg().isRequired().withLongOpt("interpreter").create());
    org.apache.commons.cli.CommandLine cli = parser.parse(options, args);

    // remove the python nature added by ProjectManagement since pydev will
    // skip all the other setup if the nature is already present.
    IProjectDescription desc = project.getDescription();
    String[] natureIds = desc.getNatureIds();
    ArrayList<String> modified = new ArrayList<String>();
    CollectionUtils.addAll(modified, natureIds);
    modified.remove(PythonNature.PYTHON_NATURE_ID);
    desc.setNatureIds(modified.toArray(new String[modified.size()]));
    project.setDescription(desc, new NullProgressMonitor());

    String pythonPath = project.getFullPath().toString();
    String interpreter = cli.getOptionValue("interpreter");
    IInterpreterManager manager = PydevPlugin.getPythonInterpreterManager();
    IInterpreterInfo info = manager.getInterpreterInfo(interpreter, null);
    if (info == null){
      throw new RuntimeException("Python interpreter not found: " + interpreter);
    }

    // construct version from the interpreter chosen.
    String version = "python " +
      IGrammarVersionProvider.grammarVersionToRep.get(info.getGrammarVersion());

    // see src.org.python.pydev.plugin.PyStructureConfigHelpers
    PythonNature.addNature(
        project, null, version, pythonPath, null, interpreter, null);
  }

  @Override
  public List<Error> update(IProject project, CommandLine commandLine)
    throws Exception
  {
    return null;
  }

  @Override
  public void delete(IProject project, CommandLine commandLine)
    throws Exception
  {
  }

  @Override
  public void refresh(IProject project, CommandLine commandLine)
    throws Exception
  {
    PythonNature pythonNature = PythonNature.getPythonNature(project);
    pythonNature.rebuildPath();
  }

  @Override
  public void refresh(IProject project, IFile file)
    throws Exception
  {
  }
}
