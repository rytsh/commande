package layout

import (
	g "github.com/AllenDang/giu"
)

type ParserLayout struct {
	Layout            *g.Layout
	ProfileNameWidget *g.LabelWidget
}

func NewParserLayout() *ParserLayout {
	l := &ParserLayout{
		ProfileNameWidget: g.Label("---"),
	}

	l.Layout = &g.Layout{
		g.Row(l.ProfileNameWidget, g.Button("Run")),
		g.Separator(),
		g.Row(g.TreeNode("Graphicsx").Layout(
			g.Label("TreeNodex1"),
		)),
	}

	return l
}
