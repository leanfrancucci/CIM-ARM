/**
 *
 * @file     xparser.c
 * @author   Aleix Conchillo Flaque <aleix@member.fsf.org>
 * @date     Tue Dec 03, 2002 00:21
 * @brief    SCEW private parser type declaration
 *
 * $Id: xparser.c,v 1.1 2008/04/28 17:17:43 yerfino Exp $
 *
 * @if copyright
 *
 * Copyright (C) 2002, 2003, 2004 Aleix Conchillo Flaque
 *
 * SCEW is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * SCEW is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
 *
 * @endif
 */

#include "xparser.h"

#include "xerror.h"
#include "xhandler.h"

#include <assert.h>
#include "str.h"

static void
xmldecl_handler1(void* data, XML_Char const* version, XML_Char const* encoding,
                int standalone)
{

    scew_parser* parser = (scew_parser*) data;

    /* Avoid warning: standalone is unused */
    (void) standalone;
    if (parser == NULL)
    {
        return;
    }

    if (parser->tree == NULL)
    {
        parser->tree = scew_tree_create();
    }

    if (parser->tree == NULL)
    {
        return;
    }

    if (version != NULL)
    {
        parser->tree->version = scew_strdup(version);
    }

    if (encoding != NULL)
    {
        parser->tree->encoding = scew_strdup(encoding);
    }

    /* by now, we ignore standalone attribute */


}

static void
start_handler1(void* data, const XML_Char* elem, const XML_Char** attr)
{

    int i = 0;
    scew_parser* parser;

	 parser = (scew_parser*) data;

    if (parser == NULL)
    {
        return;
    }

    if ((parser->tree == NULL) || (scew_tree_root(parser->tree) == NULL))
    {
        if (parser->tree == NULL)
        {
            parser->tree = scew_tree_create();
        }
        parser->current = scew_tree_add_root(parser->tree, elem);
    }
    else
    {
        stack_push(&parser->stack, parser->current);
        parser->current = scew_element_add(parser->current, elem);
    }

    for (i = 0; attr[i]; i += 2)
    {
        scew_element_add_attr_pair(parser->current, attr[i], attr[i + 1]);
    }

}

static void
end_handler1(void* data, const XML_Char* elem)
{

    XML_Char* contents = NULL;
    scew_element* current = NULL;
    scew_parser* parser = (scew_parser*) data;

    /* Avoid warning: elem is unused */
    (void) elem;

    if (parser == NULL)
    {
        return;
    }

    current = parser->current;
    if ((current != NULL) && (current->contents != NULL))
    {
        if (parser->ignore_whitespaces)
        {
            scew_strtrim(current->contents);
            if (scew_strlen(current->contents) == 0)
            {
                free(current->contents);
                current->contents = NULL;
            }
        }
        else
        {
            contents = scew_strdup(current->contents);
            scew_strtrim(contents);
            if (scew_strlen(contents) == 0)
            {
                free(current->contents);
                current->contents = NULL;
            }
            free(contents);
        }
    }
    parser->current = stack_pop(&parser->stack);

}

static void
char_handler1(void* data, const XML_Char* s, int len)
{

    int total = 0;
    int total_old = 0;
    scew_element* current = NULL;
    scew_parser* parser = (scew_parser*) data;

    if (parser == NULL)
    {
        return;
    }

    current = parser->current;

    if (current == NULL)
    {
        return;
    }

    if (current->contents != NULL)
    {
        total_old = scew_strlen(current->contents);
    }
    total = (total_old + len + 1) * sizeof(XML_Char);
    current->contents = (XML_Char*) realloc(current->contents, total);
		assert(current->contents);
    if (total_old == 0)
    {
        current->contents[0] = '\0';
    }

    scew_strncat(current->contents, s, len);

}

static void 
comment_handler1(void * udata, const XML_Char* s)
{

}
unsigned int
init_expat_parser(scew_parser* parser)
{
    assert(parser != NULL);

    parser->parser = XML_ParserCreate(NULL);
    if (parser->parser == NULL)
    {
        set_last_error(scew_error_no_memory);
        return 0;
    }

    /* initialize Expat handlers */
    XML_SetXmlDeclHandler(parser->parser, xmldecl_handler1);
    XML_SetCharacterDataHandler(parser->parser, char_handler1);
    XML_SetUserData(parser->parser, parser);
    XML_SetStartElementHandler  (parser->parser, (XML_StartElementHandler)  start_handler1);
    XML_SetEndElementHandler    (parser->parser, (XML_EndElementHandler)    end_handler1);
    XML_SetCommentHandler       (parser->parser, (XML_CommentHandler)       comment_handler1);

    return 1;
}

stack_element*
stack_push(stack_element** stack, scew_element* element)
{
    stack_element* new_elem = (stack_element*) calloc(1, sizeof(stack_element));

    if (new_elem != NULL)
    {
        new_elem->element = element;
        if (stack != NULL)
        {
            new_elem->prev = *stack;
        }
        *stack = new_elem;
    }

    return new_elem;
}

scew_element*
stack_pop(stack_element** stack)
{
    scew_element* element = NULL;
    stack_element* sk_elem = NULL;

    if (stack != NULL)
    {
        sk_elem = *stack;
        if (sk_elem != NULL)
        {
            *stack = sk_elem->prev;
            element = sk_elem->element;
            free(sk_elem);
        }
    }

    return element;
}
