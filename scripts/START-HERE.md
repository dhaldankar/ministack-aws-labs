# AWS Playground

Open the [lab catalog](http://localhost:4000) in your browser. Start with **Orientation**, then choose an exercise.

In the integrated Bash terminal, run:

```bash
lab list
lab_dir=$(lab start orientation) && cd "$lab_dir"
```

Follow the walkthrough in your browser. Your exercise appears in the Explorer after you start it. Run the checker when prompted:

```bash
lab check orientation
```

To resume, run the same start command with the lab ID. Your edits and Terraform state are saved in the workspace volume. Run each walkthrough's cleanup steps before resetting or discarding its files.
